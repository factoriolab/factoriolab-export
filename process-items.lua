local entities = require("entities")
local items = require("items")
local iterate_collection = require("iterate-collection")
local process_recipes = require("process-recipes")
local state = require("state")

return function()
  local item_map = {}

  local function process_item(name, proto)
    local id = "item-" .. name
    if proto.parameter then
      -- Mark as removed so associated recipes will be filtered out
      state.items_removed[id] = true
      return
    end

    local sprite = "item/" .. name
    local item = {
      id = id,
      icon = sprite,
      stack = proto.stack_size,
      rocketCapacity = proto.weight and proto.weight > 0 and
        math.floor(prototypes.utility_constants.default_rocket_lift_weight / proto.weight) or
        nil
    }

    if proto.fuel_value > 0 then
      item.fuel = items.fuel(proto)
      state.items_used[item.id] = true
    end

    if proto.type == "module" then
      item.module = items.module(proto)
      state.items_used[item.id] = true
    end

    table.insert(state.items_meta, {item = item, sprite = sprite, scale = 2, proto = proto})
    state.item_map[item.id] = item
    item_map[name] = item
  end

  local function process_entity(name, proto)
    if proto.parameter then
      return
    end

    if proto.type == "beacon" then
      local item = item_map[name] or entities.item(proto)
      item.beacon = entities.beacon(proto)
      state.items_used[item.id] = true
    elseif proto.type == "transport-belt" then
      local item = item_map[name] or entities.item(proto)
      item.belt = entities.belt(proto)
      state.items_used[item.id] = true
    elseif proto.type == "pump" then
      local item = item_map[name] or entities.item(proto)
      item.pipe = entities.pipe(proto)
      state.items_used[item.id] = true
    elseif
      proto.type == "assembling-machine" or proto.type == "boiler" or proto.type == "burner-generator" or
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
      state.items_used[item.id] = true
    elseif proto.type == "cargo-wagon" then
      local item = item_map[name] or entities.item(proto)
      item.cargoWagon = entities.cargo_wagon(proto)
      state.items_used[item.id] = true
    elseif proto.type == "fluid-wagon" then
      local item = item_map[name] or entities.item(proto)
      item.fluidWagon = entities.fluid_wagon(proto)
      state.items_used[item.id] = true
    elseif proto.type == "inserter" then
      local item = item_map[name] or entities.item(proto)
      item.inserter = entities.inserter(proto)
      state.items_used[item.id] = true
    end
  end

  local function process_fluid(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "fluid/" .. name
    local item = {
      id = "fluid-" .. name,
      icon = sprite
    }

    table.insert(state.items_meta, {item = item, sprite = sprite, scale = 2, proto = proto})
    state.item_map[item.id] = item
  end

  iterate_collection(
    prototypes.item,
    process_item,
    function()
      iterate_collection(
        prototypes.entity,
        process_entity,
        function()
          iterate_collection(prototypes.fluid, process_fluid, process_recipes)
        end
      )
    end
  )
end
