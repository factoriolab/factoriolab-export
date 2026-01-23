local utils = require("utils")

local entity_utils = {}

function entity_utils.disallowed_effects(entity)
  if not entity.module_inventory_size then
    return nil
  end

  local result = {}
  for effect, allow in pairs(entity.allowed_effects) do
    if allow == false then
      table.insert(result, effect)
    end
  end

  return #result and result or nil
end

function entity_utils.size(entity)
  local box = entity.collision_box
  if not box then
    return {0, 0}
  end

  local left, top, right, bottom = 0
  if box[1] then
    left = box[1][1]
    top = box[1][2]
    right = box[2][1]
    bottom = box[2][2]
  else
    left = box.left_top.x
    top = box.left_top.y
    right = box.right_bottom.x
    bottom = box.right_bottom.y
  end

  if entity.has_flag("placeable-off-grid") then
    return {right - left, bottom - top}
  end

  local width_even = (entity.tile_width % 2) == 0
  local height_even = (entity.tile_height % 2) == 0

  -- Count tile centers occluded by collision box
  local tile_width, tile_height
  if width_even then
    -- Box origin is offset 0.5 from tile centers
    tile_width = math.floor(0.5 - left) + math.floor(0.5 + right)
  else
    -- Add 1 for the box's {0, 0}
    tile_width = 1 + math.floor(-left) + math.floor(right)
  end

  if height_even then
    tile_height = math.floor(0.5 - top) + math.floor(0.5 + bottom)
  else
    tile_height = 1 + math.floor(-top) + math.floor(bottom)
  end

  return {tile_width, tile_height}
end

function entity_utils.item(state, localised_strings, entity)
  local sprite = "entity/" .. entity.name
  local item = {
    id = entity.name,
    icon = sprite,
    row = 0,
    category = "entity"
  }
  table.insert(state.data.items, item)
  table.insert(state.icons, {sprite = sprite, scale = 2})
  table.insert(localised_strings, entity.localised_name)
  return item
end

function entity_utils.beacon(entity)
  local usage_num = entity.get_max_energy_usage()
  local beacon = {
    effectivity = entity.distribution_effectivity,
    modules = entity.module_inventory_size,
    range = entity.get_supply_area_distance(),
    type = entity.electric_energy_source_prototype and "electric" or nil,
    usage = utils.convert_energy(usage_num),
    disallowedEffects = entity_utils.disallowed_effects(entity),
    size = entity_utils.size(entity),
    profile = entity.profile
  }

  local quality_record = {}
  for name, quality in pairs(prototypes.quality) do
    local variant = {}

    if quality.level > 0 and entity.distribution_effectivity_bonus_per_quality_level then
      variant.effectivity = beacon.effectivity + quality.level * entity.distribution_effectivity_bonus_per_quality_level
    end

    if quality.beacon_module_slots_bonus and entity.quality_affects_module_slots then
      variant.modules = beacon.modules + quality.beacon_module_slots_bonus
    end

    local range = entity.get_supply_area_distance(name)
    if range ~= beacon.range then
      variant.range = range
    end

    local usage = entity.get_max_energy_usage(name)
    if usage ~= usage_num then
      variant.usage = utils.convert_energy(usage)
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    beacon.qualityRecord = quality_record
  end

  return beacon
end

function entity_utils.pump(entity)
  local speed_num = entity.get_pumping_speed()
  local pipe = {
    speed = speed_num * 60
  }

  local quality_record = {}
  for name, quality in pairs(prototypes.quality) do
    local variant = {}

    local speed = entity.get_pumping_speed(name)
    if speed ~= speed_num then
      variant.speed = speed * 60
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    pipe.qualityRecord = quality_record
  end

  return pipe
end

function eval_surface_conditions(location, conditions)
  for _, condition in pairs(conditions) do
    local value =
      location.surface_properties and location.surface_properties[condition.property] or
      prototypes.surface_property[condition.property].default_value
    if condition.max and value > condition.max then
      return false
    end

    if condition.min and value < condition.min then
      return false
    end
  end

  return true
end

function entity_utils.locations(entity)
  if not entity.surface_conditions then
    return nil
  end

  local result = {}

  for name, proto in pairs(prototypes.space_location) do
    if proto.type == "planet" and eval_surface_conditions(proto, entity.surface_conditions) then
      table.insert(result, name)
    end
  end

  for name, proto in pairs(prototypes.surface) do
    if eval_surface_conditions(proto, entity.surface_conditions) then
      table.insert(result, name)
    end
  end

  if #result == #prototypes.space_location + #prototypes.surface then
    return nil
  end

  return result
end

function entity_utils.agricultural_tower(entity)
  local usage_num = entity.get_max_energy_usage()
  local machine = {
    speed = 1,
    type = entity.electric_energy_source_prototype and "electric" or entity.burner_prototype and "burner" or nil,
    fuelCategories = entity.burner_prototype and entity.burner_prototype.fuel_categories or nil,
    usage = utils.convert_energy(usage_num),
    drain = entity.electric_energy_source_prototype and entity.electric_energy_source_prototype.drain > 0 and
      utils.convert_energy(entity.electric_energy_source_prototype.drain) or
      nil,
    pollution = entity.emissions_per_second["pollution"] > 0 and entity.emissions_per_second["pollution"] * 60 or nil,
    size = entity_utils.size(entity),
    entityType = entity.type,
    locations = entity_utils.locations(entity)
  }

  -- TODO: Qualities?

  return machine
end

return entity_utils
