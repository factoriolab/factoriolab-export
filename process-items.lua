local entities = require("entities")
local items = require("items")
local get_row_fn = require("get-row-fn")
local process_collection = require("process-collection")
local state = require("state")
local translations = require("translations")
local process_recipes = require("process-recipes")
local technologies = require("technologies")

return function()
  log("init process_items")
  local item_row = get_row_fn()
  local item_map = {}

  local function process_item(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "item/" .. name
    local item = {
      id = "item-" .. name,
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

    table.insert(state.data.items, item)
    state.item_map[item.id] = item
    item_map[name] = item
    table.insert(state.icons, {sprite = sprite, scale = 2})
    translations.add(proto.localised_name, item)
  end

  local function process_entity(name, proto)
    if proto.parameter then
      return
    end

    if proto.type == "beacon" then
      local item = item_map[name] or entities.item(proto)
      item.beacon = entities.beacon(proto)
    elseif proto.type == "transport-belt" then
      local item = item_map[name] or entities.item(proto)
      item.belt = entities.belt(proto)
    elseif proto.type == "pump" then
      local item = item_map[name] or entities.item(proto)
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
      local item = item_map[name] or entities.item(proto)
      item.machine = entities.machine(proto, item)
    elseif proto.type == "cargo-wagon" then
      local item = item_map[name] or entities.item(proto)
      item.cargoWagon = entities.cargo_wagon(proto)
    elseif proto.type == "fluid-wagon" then
      local item = item_map[name] or entities.item(proto)
      item.fluidWagon = entities.fluid_wagon(proto)
    elseif proto.type == "inserter" then
      local item = item_map[name] or entities.item(proto)
      item.inserter = entities.inserter(proto)
    end
  end

  local function process_fluid(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "fluid/" .. name
    local item = {
      id = "fluid-" .. name,
      icon = sprite,
      row = item_row(proto),
      category = proto.group.name
    }
    table.insert(state.data.items, item)
    state.item_map[item.id] = item
    table.insert(state.icons, {sprite = sprite, scale = 2})
    translations.add(proto.localised_name, item)
  end

  local function process_technology(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "technology/" .. name
    local item = {
      id = "technology-" .. name,
      icon = sprite,
      row = #proto.research_unit_ingredients,
      category = "technology",
      technology = technologies.technology(proto)
    }
    table.insert(state.data.items, item)
    table.insert(state.icons, {sprite = sprite, scale = 0.5})
    translations.add(proto.localised_name, item)
  end

  local function finalize_fluids()
    log("init finalize_fluids")
    process_collection(prototypes.technology, process_technology, process_recipes)
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
