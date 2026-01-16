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

function entity_utils.beacon(entity, quality)
  return {
    effectivity = entity.distribution_effectivity,
    modules = entity.module_inventory_size,
    range = entity.get_supply_area_distance(quality),
    type = entity.electric_energy_source_prototype and "electric" or nil,
    usage = utils.convert_energy(entity.energy_usage),
    disallowedEffects = entity_utils.disallowed_effects(entity),
    size = entity_utils.size(entity),
    profile = entity.profile
  }
end

return entity_utils
