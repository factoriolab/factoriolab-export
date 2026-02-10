local get_row_fn = require("get-row-fn")
local process_collection = require("process-collection")
local state = require("state")
local translate_collection = require("translate-collection")
local process_locations = require("process-locations")
local recipes = require("recipes")
local utils = require("utils")

return function()
  log("init process_recipes")
  local localised_strings = {}
  local recipe_row = get_row_fn()

  local function process_recipe(name, proto)
    local sprite = "recipe/" .. name
    local out, catalyst = recipes.products(proto)
    local recipe = {
      id = name,
      icon = sprite,
      row = recipe_row(proto),
      category = proto.group.name,
      time = proto.energy,
      ["in"] = recipes.ingredients(proto),
      out = out,
      catalyst = catalyst,
      disallowedEffects = utils.disallowed_effects(proto),
      locations = utils.locations(proto),
      producers = state.producers.crafting[proto.category],
      flags = {}
    }

    if proto.category == "recycling" then
      table.insert(recipe.flags, "recycling")
    end

    if state.recipes_locked[name] then
      table.insert(recipe.flags, "locked")
    end

    if next(recipe.flags) == nil then
      recipe.flags = nil
    end

    table.insert(state.data.recipes, recipe)
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function process_entity(name, proto)
    if proto.type == "resource" then
      -- Resource recipes
      if proto.mineable_properties.minable and proto.mineable_properties.products then
        local out, catalyst, total = recipes.products(proto.mineable_properties)
        local firstOut = next(out)
        local item = state.item_map[firstOut]

        local producers = state.producers.resource[proto.resource_category]
        local recipeIn = {}
        if proto.mineable_properties.required_fluid and proto.mineable_properties.fluid_amount then
          recipeIn["fluid-" .. proto.mineable_properties.required_fluid] = proto.mineable_properties.fluid_amount
          producers = state.producers.resource_fluid[proto.resource_category]
        end

        local locations = {}
        for surface_name, surface_proto in pairs(prototypes.space_location) do
          if utils.has_resource(surface_proto, name) then
            table.insert(locations, surface_name)
          end
        end

        if item and #locations > 0 and #producers > 0 and total > 0 then
          local recipe = {
            id = "resource-" .. name,
            icon = item.icon,
            row = recipe_row(proto),
            category = proto.group.name,
            time = proto.mineable_properties.mining_time,
            ["in"] = recipeIn,
            out = out,
            catalyst = catalyst,
            producers = producers,
            cost = 100 / total,
            flags = {"mining"},
            locations = locations,
            name = item.name
          }

          if proto.infinite_resource then
            table.insert(recipe.flags, "infinite")
          end

          table.insert(state.data.recipes, recipe)
        end
      end
    end
  end

  local function process_fluid(name, proto)
    local item = state.item_map["fluid-" .. name]

    -- Offshore pump recipes
    local locations = {}
    for surface_name, surface_proto in pairs(prototypes.space_location) do
      if utils.has_ocean(surface_proto, name) then
        table.insert(locations, surface_name)
      end
    end

    if #locations > 0 then
      local producers = {}
      for entity_name, info in pairs(state.machines.offshore_pump) do
        if not info.output or info.output == name then
          table.insert(producers, info.id)
        end
      end

      if #producers > 0 then
        local recipe = {
          id = "offshore-pump-" .. name,
          icon = item.icon,
          row = recipe_row(proto),
          category = proto.group.name,
          time = 1,
          ["in"] = {},
          out = {[item.id] = 1},
          producers = producers,
          locations = locations,
          name = item.name
        }

        table.insert(state.data.recipes, recipe)
      end
    end

    -- Boiler recipes
    local input_producers = {}
    for entity_name, info in pairs(state.machines.boiler) do
      if info.output == name and info.input then
        if not input_producers[info.input] then
          input_producers[info.input] = {}
        end

        table.insert(input_producers[info.input], info.id)
      end
    end

    for input, producers in pairs(input_producers) do
      local input_id = "fluid-" .. input
      local recipe = {
        id = "boiler-" .. name,
        icon = item.icon,
        row = recipe_row(proto),
        category = proto.group.name,
        time = 1,
        ["in"] = {[input_id] = 1},
        out = {[item.id] = 10},
        producers = producers,
        name = item.name
      }

      table.insert(state.data.recipes, recipe)
    end
  end

  -- TODO: Not-recipe recipes
  -- Rocket launch recipes
  -- Burn recipes
  -- Spoil recipes
  -- Agriculture recipes
  -- Technology recipes
  -- Asteroid recipes

  local function finalize_fluids()
    translate_collection(state.player, localised_strings, state.data.recipes, process_locations)
    script.on_event(defines.events.on_tick, nil)
  end

  local function finalize_entities()
    process_collection(prototypes.fluid, process_fluid, finalize_fluids)
  end

  local function finalize_recipes()
    process_collection(prototypes.entity, process_entity, finalize_entities)
  end

  process_collection(prototypes.recipe, process_recipe, finalize_recipes)
  log("end process_recipes")
end
