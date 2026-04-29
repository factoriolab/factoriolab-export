local iterate_collection = require("iterate-collection")
local process_categories = require("process-categories")
local recipes = require("recipes")
local state = require("state")
local utils = require("utils")

return function()
  local function process_item_recipes(name, proto)
    if proto.parameter then
      return
    end

    if #proto.rocket_launch_products > 0 then
      -- Rocket launch recipes
      local product_proto = utils.first_product_proto(proto.rocket_launch_products)
      local out, catalyst, total = recipes.products(proto.rocket_launch_products)
      local first_out = next(out)
      local item = state.item_map[first_out]

      for entity_name, info in pairs(state.machines.silo) do
        local recipe_in = {[name] = 1}
        for item_id, amount in pairs(info.recipe_in) do
          if not recipe_in[item_id] then
            recipe_in[item_id] = 0
          end

          recipe_in[item_id] = recipe_in[item_id] + amount
        end

        local recipe = {
          id = "launch-" .. info.id .. "-" .. name,
          icon = item.icon,
          time = 40.6,
          ["in"] = recipe_in,
          out = out,
          catalyst = catalyst,
          part = info.part,
          producers = {info.id}
        }

        recipes.store_used_items(recipe)
        table.insert(
          state.recipes_meta,
          {
            recipe = recipe,
            localised_name = {"factoriolab-export.launch-item", proto.localised_name},
            proto = product_proto
          }
        )
      end
    end

    if proto.burnt_result then
      -- Burn recipes
      local producers = state.producers.burner[proto.fuel_category]
      if producers then
        local item = state.item_map["item-" .. proto.burnt_result.name]

        local recipe = {
          id = "burn-" .. name,
          icon = item.icon,
          time = 1,
          ["in"] = {["item-" .. name] = 0},
          out = {[item.id] = 0},
          producers = producers,
          flags = {"burn"}
        }

        recipes.store_used_items(recipe)
        table.insert(
          state.recipes_meta,
          {
            recipe = recipe,
            localised_name = {"factoriolab-export.x-from-y", proto.burnt_result.localised_name, proto.localised_name},
            proto = proto.burnt_result
          }
        )
      end
    end

    if proto.spoil_result then
      -- Spoil recipes
      local item = state.item_map["item-" .. proto.spoil_result.name]
      local recipe = {
        id = "spoil-" .. name,
        icon = item.icon,
        time = 1,
        ["in"] = {["item-" .. name] = 1},
        out = {[item.id] = 1}
      }

      recipes.store_used_items(recipe)
      table.insert(
        state.recipes_meta,
        {
          recipe = recipe,
          localised_name = {"factoriolab-export.x-from-y", proto.spoil_result.localised_name, proto.localised_name},
          proto = proto.spoil_result
        }
      )
    end

    if
      proto.plant_result and proto.plant_result.mineable_properties.minable and
        proto.plant_result.mineable_properties.products
     then
      -- Agriculture recipes
      local product_proto = utils.first_product_proto(proto.plant_result.mineable_properties.products)
      local out, catalyst, total = recipes.products(proto.plant_result.mineable_properties.products)
      local first_out = next(out)
      local item = state.item_map[first_out]
      local sprite = "entity/" .. proto.plant_result.name
      table.insert(state.icons, {sprite = sprite, scale = 2})
      local recipe = {
        id = "harvest-" .. proto.plant_result.name,
        icon = sprite,
        time = proto.plant_result.growth_ticks / 60,
        ["in"] = {["item-" .. name] = 1},
        out = out,
        catalyst = catalyst,
        cost = 100 / total,
        locations = utils.locations(proto.plant_result)
      }

      recipes.store_used_items(recipe)
      table.insert(
        state.recipes_meta,
        {
          recipe = recipe,
          localised_name = {"factoriolab-export.harvest-item", proto.plant_result.localised_name},
          proto = product_proto
        }
      )
    end
  end

  local function process_entity_recipes(name, proto)
    if proto.parameter then
      return
    end

    if proto.type == "resource" then
      -- Resource recipes
      if proto.mineable_properties.minable and proto.mineable_properties.products then
        local product_proto = utils.first_product_proto(proto.mineable_properties.products)
        local out, catalyst, total = recipes.products(proto.mineable_properties.products)
        local first_out = next(out)
        local item = state.item_map[first_out]

        local producers = state.producers.resource[proto.resource_category]
        local recipe_in = {}
        if proto.mineable_properties.required_fluid and proto.mineable_properties.fluid_amount then
          recipe_in["fluid-" .. proto.mineable_properties.required_fluid] = proto.mineable_properties.fluid_amount
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
            time = proto.mineable_properties.mining_time,
            ["in"] = recipe_in,
            out = out,
            catalyst = catalyst,
            producers = producers,
            cost = 100 / total,
            flags = {"mining"},
            locations = locations
          }

          if proto.infinite_resource then
            table.insert(recipe.flags, "infinite")
          end

          recipes.store_used_items(recipe)
          table.insert(
            state.recipes_meta,
            {
              recipe = recipe,
              localised_name = {"factoriolab-export.mining-item", proto.localised_name},
              proto = product_proto
            }
          )
        end
      end
    end
  end

  local function process_fluid_recipes(name, proto)
    if proto.parameter then
      return
    end

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
          time = 1,
          ["in"] = {},
          out = {[item.id] = 1},
          producers = producers,
          locations = locations
        }

        recipes.store_used_items(recipe)
        table.insert(
          state.recipes_meta,
          {
            recipe = recipe,
            localised_name = {"factoriolab-export.offshore-pump-item", proto.localised_name},
            proto = proto
          }
        )
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
        time = 1,
        ["in"] = {[input_id] = 1},
        out = {[item.id] = 10},
        producers = producers
      }

      recipes.store_used_items(recipe)
      table.insert(
        state.recipes_meta,
        {
          recipe = recipe,
          localised_name = {"factoriolab-export.boil-item", prototypes.fluid[input].localised_name},
          proto = proto
        }
      )
    end
  end

  local function process_recipe(name, proto)
    if proto.parameter or not recipes.included(proto) then
      return
    end

    local sprite = "recipe/" .. name
    local out, catalyst = recipes.products(proto.products)
    local recipe = {
      id = name,
      icon = sprite,
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
    else
      recipes.store_used_items(recipe)
    end

    if state.recipes_locked[name] then
      table.insert(recipe.flags, "locked")
    end

    if next(recipe.flags) == nil then
      recipe.flags = nil
    end

    table.insert(state.recipes_meta, {recipe = recipe, sprite = sprite, scale = 2, proto = proto})
  end

  iterate_collection(
    prototypes.recipe,
    process_recipe,
    function()
      iterate_collection(
        prototypes.item,
        process_item_recipes,
        function()
          iterate_collection(
            prototypes.entity,
            process_entity_recipes,
            function()
              iterate_collection(prototypes.fluid, process_fluid_recipes, process_categories)
            end
          )
        end
      )
    end
  )
end
