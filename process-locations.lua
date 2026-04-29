local iterate_collection = require("iterate-collection")
local process_qualities = require("process-qualities")
local recipes = require("recipes")
local state = require("state")
local translations = require("translations")

local asteroid_results = {}
local function parse_asteroid(name)
  if asteroid_results[name] then
    return
  end

  asteroid_results[name] = {}

  local asteroid = prototypes.entity[name]
  if asteroid.dying_trigger_effect then
    for _, effect in ipairs(asteroid.dying_trigger_effect) do
      if effect.type == "create-asteroid-chunk" then
        local id = "item-" .. effect.asteroid_name
        local count = (effect.offsets and #effect.offsets) or 1
        local value = count * effect.probability
        recipes.add_value(asteroid_results[name], id, value)
      elseif effect.type == "create-entity" then
        parse_asteroid(effect.entity_name)

        local count = (effect.offsets and #effect.offsets) or 1
        for key, value in pairs(asteroid_results[effect.entity_name]) do
          value = count * value
          recipes.add_value(asteroid_results[name], key, value)
        end
      end
    end
  end
end

return function()
  local function process_space_location(name, proto)
    if proto.parameter or proto.hidden then
      return
    end

    local sprite = "space-location/" .. name
    if proto.type == "planet" then
      local location = {id = name, icon = sprite}
      table.insert(state.data.locations, location)
      table.insert(state.icons, {sprite = sprite, scale = 2})
      translations.add(proto.localised_name, location)
    end

    if proto.asteroid_spawn_definitions then
      local out = {}
      for _, spawn in ipairs(proto.asteroid_spawn_definitions) do
        if spawn.type == "asteroid-chunk" then
          local id = "item-" .. spawn.asteroid
          recipes.add_value(out, id, spawn.probability)
        else
          parse_asteroid(spawn.asteroid)
          for key, value in pairs(asteroid_results[spawn.asteroid]) do
            recipes.add_value(out, key, spawn.probability * value)
          end
        end
      end

      if next(out) then
        local recipe = {
          id = proto.type .. "-" .. proto.name,
          icon = sprite,
          time = 1,
          ["in"] = {},
          out = recipes.as_percentage(out),
          cost = 100
        }

        if proto.type ~= "planet" then
          -- Make sure the icon still gets added
          table.insert(state.icons, {sprite = sprite, scale = 2})
        end

        recipes.store_used_items(recipe)
        table.insert(
          state.recipes_meta,
          {
            recipe = recipe,
            localised_name = {"factoriolab-export.planet-asteroid-mining", proto.localised_name},
            proto = proto
          }
        )
      end
    end
  end

  local function process_space_connection(name, proto)
    if proto.parameter or proto.hidden then
      return
    end

    if proto.asteroid_spawn_definitions then
      local out = {}
      for _, spawn in ipairs(proto.asteroid_spawn_definitions) do
        if spawn.type == "asteroid-chunk" then
          local id = "item-" .. spawn.asteroid
          for _, point in ipairs(spawn.spawn_points) do
            recipes.add_value(out, id, point.probability)
          end
        else
          parse_asteroid(spawn.asteroid)
          for key, value in pairs(asteroid_results[spawn.asteroid]) do
            for _, point in ipairs(spawn.spawn_points) do
              recipes.add_value(out, key, point.probability * value)
            end
          end
        end
      end

      if next(out) then
        local sprite = "space-connection/" .. name
        local recipe = {
          id = proto.type .. "-" .. proto.name,
          icon = sprite,
          time = 1,
          ["in"] = {},
          out = recipes.as_percentage(out),
          cost = 100
        }

        table.insert(state.icons, {sprite = sprite, scale = 2})
        recipes.store_used_items(recipe)
        table.insert(
          state.recipes_meta,
          {
            recipe = recipe,
            localised_name = {
              "factoriolab-export.connection-asteroid-mining",
              proto.from.localised_name,
              proto.to.localised_name
            },
            proto = proto
          }
        )
      end
    end
  end

  local function process_surface(name, proto)
    if proto.parameter or proto.hidden then
      return
    end

    local sprite = "surface/" .. name
    local location = {id = name, icon = sprite}
    table.insert(state.data.locations, location)
    table.insert(state.icons, {sprite = sprite, scale = 2})
    translations.add(proto.localised_name, location)
  end

  iterate_collection(
    prototypes.space_location,
    process_space_location,
    function()
      iterate_collection(
        prototypes.space_connection,
        process_space_connection,
        function()
          iterate_collection(prototypes.surface, process_surface, process_qualities)
        end
      )
    end
  )
end
