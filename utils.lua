local utils = {}

function convert_energy(energy)
  return energy and energy > 0 and energy / 1000 * 60 or nil
end

function utils.usage(entity, quality)
  if entity.type == "asteroid-collector" then
    return nil
  end

  local usage = entity.get_max_energy_usage(quality)
  return convert_energy(usage)
end

function utils.drain(entity)
  if entity.type == "asteroid-collector" then
    return nil
  end

  local drain = entity.electric_energy_source_prototype and entity.electric_energy_source_prototype.drain
  return convert_energy(drain)
end

function utils.disallowed_effects(entity)
  if not entity.allowed_effects then
    return nil
  end

  local result = {}
  for effect, allow in pairs(entity.allowed_effects) do
    if allow == false then
      table.insert(result, effect)
    end
  end

  return #result > 0 and result or nil
end

function utils.size(entity)
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

function utils.locations(entity)
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

function utils.energy_type(entity)
  return entity.electric_energy_source_prototype and "electric" or entity.burner_prototype and "burner" or nil
end

function utils.is_crafting_machine(entity)
  return entity.type == "assembling-machine" or entity.type == "furnace" or entity.type == "rocket-silo"
end

function utils.modules(entity, quality)
  if quality and entity.quality_affects_module_slots then
    if quality.beacon_module_slots_bonus and entity.type == "beacon" then
      return entity.module_inventory_size + quality.beacon_module_slots_bonus
    elseif quality.crafting_machine_slots_bonus and utils.is_crafting_machine(entity) then
      return entity.module_inventory_size + quality.crafting_machine_module_slots_bonus
    elseif quality.mining_drill_slots_bonus and entity.type == "mining-drill" then
      return entity.module_inventory_size + quality.mining_drill_module_slots_bonus
    elseif quality.lab_module_slots_bonus and entity.type == "lab" then
      return entity.module_inventory_size + quality.lab_module_slots_bonus
    end
  end

  return entity.module_inventory_size
end

function utils.has_ocean(planet, fluid)
  if
    planet.type ~= "planet" or not planet.map_gen_settings or
      not planet.map_gen_settings.autoplace_settings.tile.settings
   then
    return false
  end

  for tile_name, settings in pairs(planet.map_gen_settings.autoplace_settings.tile.settings) do
    local tile = prototypes.tile[tile_name]
    if tile.fluid and tile.fluid.name == fluid then
      return true
    end
  end

  return false
end

return utils
