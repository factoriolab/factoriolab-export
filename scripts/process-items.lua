local entity_utils = require("entity-utils")
local process_collection = require("process-collection")
local process_recipes = require("process-recipes")
local state = require("state")
local translate_collection = require("translate-collection")

return function()
  log("init process_items")
  local localised_strings = {}
  local item_row = utils.get_row_fn()
  local item_map = {}

  -- TODO: Include qualities?
  -- TODO: Crawl resources

  local function process_item(name, proto)
    local sprite = "item/" .. name
    local item = {
      id = name,
      icon = sprite,
      row = item_row(proto),
      category = proto.group.name,
      stack = proto.stack_size,
      rocketCapacity = proto.weight and proto.weight > 0 and
        math.floor(prototypes.utility_constants.rocket_lift_weight / proto.weight) or
        nil
    }

    -- TODO: Check for fuel?

    table.insert(state.data.items, item)
    item_map[name] = item
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function process_entity(name, proto)
    if proto.type == "beacon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.beacon = entity_utils.beacon(proto)
    elseif proto.type == "transport-belt" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.belt = {speed = proto.belt_speed * 8 * 60}
    elseif proto.type == "pump" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.pipe = entity_utils.pump(proto)
    elseif proto.type == "agricultural-tower" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = entity_utils.agricultural_tower(proto)
    elseif proto.type == "assembling-machine" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "asteroid-collector" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "boiler" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "burner-generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "furnace" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "fusion-generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "fusion-reactor" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "lab" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "mining-drill" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "offshore-pump" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "reactor" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "rocket-silo" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "module" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.module = {} --TODO
    elseif proto.type == "cargo-wagon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.cargoWagon = {} --TODO
    elseif proto.type == "fluid-wagon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.fluidWagon = {} --TODO
    elseif proto.type == "inserter" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.inserter = {} --TODO
    end
  end

  local function process_fluid(name, proto)
    local sprite = "fluid/" .. name
    table.insert(
      state.data.items,
      {
        id = name,
        icon = sprite,
        row = item_row(proto),
        category = proto.group.name
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function process_technology(name, proto)
    local sprite = "technology/" .. name
    -- TODO: Include technology info
    table.insert(
      state.data.items,
      {
        id = name,
        icon = sprite,
        row = item_row(proto),
        category = "technology"
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 0.5})
    table.insert(localised_strings, proto.localised_name)
  end

  local function finalize_technologies()
    log("init finalize_technologies")
    translate_collection(state.player, localised_strings, state.data.items, process_recipes)
    script.on_event(defines.events.on_tick, nil)
    log("end finalize_technologies")
  end

  local function finalize_fluids()
    log("init finalize_fluids")
    process_collection(prototypes.technology, process_technology, finalize_technologies)
    log("end finalize_fluids")
  end

  local function finalize_entities()
    log("init finalize_entities")
    process_collection(prototypes.fluid, process_fluid, finalize_fluids)
    log("end finalize_entities")
  end

  local function finalize_items()
    log("init finalize_items")
    process_collection(prototypes.entity, process_entity, finalize_entities)
    log("end finalize_items")
  end

  process_collection(prototypes.item, process_item, finalize_items)
  log("end process_items")
end
