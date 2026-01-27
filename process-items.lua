local entities = require("entities")
local items = require("items")
local get_row_fn = require("get-row-fn")
local process_collection = require("process-collection")
local state = require("state")
local translate_collection = require("translate-collection")
local process_recipes = require("process-recipes")

return function()
  log("init process_items")
  local localised_strings = {}
  local item_row = get_row_fn()
  local item_map = {}

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

    if proto.fuel_value > 0 then
      item.fuel = items.fuel(proto)
    end

    if proto.type == "module" then
      item.module = items.module(proto)
    end
    -- TODO: Check for fuel?

    table.insert(state.data.items, item)
    item_map[name] = item
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function process_entity(name, proto)
    if proto.type == "beacon" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.beacon = entities.beacon(proto)
    elseif proto.type == "transport-belt" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.belt = entities.belt(proto)
    elseif proto.type == "pump" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.pipe = entities.pipe(proto)
    elseif
      proto.type == "agricultural-tower" or proto.type == "assembling-machine" or proto.type == "asteroid-collector" or
        proto.type == "boiler" or
        proto.type == "burner-generator" or
        proto.type == "furnace" or
        proto.type == "fusion-generator" or
        proto.type == "fusion-reactor" or
        proto.type == "generator" or
        proto.type == "lab" or
        proto.type == "mining-drill" or
        proto.type == "offshore-pump" or
        proto.type == "reactor" or
        proto.type == "rocket-silo"
     then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.machine = entities.machine(proto)
    elseif proto.type == "cargo-wagon" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.cargoWagon = entities.cargo_wagon(proto)
    elseif proto.type == "fluid-wagon" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.fluidWagon = entities.fluid_wagon(proto)
    elseif proto.type == "inserter" then
      local item = item_map[name] or entities.item(localised_strings, proto)
      item.inserter = entities.inserter(proto)
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
