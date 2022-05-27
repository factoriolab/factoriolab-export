local collect_data = require("collect-data")
local entity_utils = require("entity-utils")
local json = require("json")
local utils = require("utils")

local folder = "factoriolab-export/"
local color_warn = {r = 1, g = 0.5, b = 0}
local color_good = {r = 0, g = 1, b = 0}

local function add_icon(hash_id, name, scale, sprite, icons)
  if hash_id ~= -1 then
    if hash_id then
      for _, icon in pairs(icons) do
        if icon.hash_id == hash_id then
          table.insert(icon.copies, name)
          return
        end
      end
    end
    table.insert(icons, {hash_id = hash_id, name = name, scale = scale, sprite = sprite, copies = {}})
  end
end

local function check_recipe_name(recipes, desired_id, backup_id, icons)
  for _, recipe in pairs(recipes) do
    if recipe.id == desired_id then
      for _, icon in pairs(icons) do
        if icon.name == recipe.id then
          table.insert(icon.copies, backup_id)
          break
        end
      end
      return backup_id
    end
  end
  return desired_id
end

local function calculate_ingredients(ingredients)
  local lab_in = {}
  for _, ingredient in pairs(ingredients) do
    lab_in[ingredient.name] = ingredient.amount
  end
  return lab_in
end

local function calculate_products(products)
  local lab_out = {}
  local total = 0
  for _, product in pairs(products) do
    local amount = product.amount
    if not amount then
      amount = (product.amount_max + product.amount_min) / 2
    end
    if product.probability then
      amount = amount * product.probability
    end
    total = total + amount
    lab_out[product.name] = amount
  end
  return lab_out, total
end

local function compare_default_min(default, name, desired_trait, desired_value)
  if
    not default or (default[2] == false and desired_trait) or
      (default[2] == desired_trait and default[3] > desired_value)
   then
    return {name, desired_trait, desired_value}
  end
  return default
end

local function compare_default_max(default, name, desired_trait, desired_value)
  if
    not default or (default[2] == false and desired_trait) or
      (default[2] == desired_trait and default[3] < desired_value)
   then
    return {name, desired_trait, desired_value}
  end
  return default
end

-- Calculate row for an item, this keeps track of last item parsed
local last_row, last_col, last_group, last_subgroup = 0, 0
local function get_row(item)
  if item.group == last_group then
    if item.subgroup ~= last_subgroup or last_col == 10 then
      last_row = last_row + 1
      last_col = 0
    end
  else
    last_row = 0
    last_col = 0
  end
  last_group = item.group
  last_subgroup = item.subgroup
  last_col = last_col + 1
  return last_row
end

local function safe_add(name, list)
  for _, n in pairs(list) do
    if n == name then
      return
    end
  end
  table.insert(list, name)
end

local function safe_add_recipe_items(recipe, list)
  for n, _ in pairs(recipe["in"]) do
    safe_add(n, list)
  end
  for n, _ in pairs(recipe.out) do
    safe_add(n, list)
  end
end

return function(player_index, language_data)
  local player = game.players[player_index]
  local player_settings = settings.get_player_settings(player)
  local dictionaries = language_data.dictionaries
  local language = language_data.language

  -- Localized names
  local group_names = dictionaries["item_group_names"]
  local item_names = dictionaries["item_names"]
  local fluid_names = dictionaries["fluid_names"]
  local recipe_names = dictionaries["recipe_names"]
  local technology_names = dictionaries["technology_names"]
  local gui_names = dictionaries["gui_technology_names"]

  local sorted_item_names, recipes_enabled = collect_data()
  local producers = {
    -- dictionary of category -> list
    burner = {},
    -- dictionary of category -> list
    crafting = {},
    -- dictionary of category -> list
    resource = {},
    -- list of names
    labs = {},
    -- list of entities
    silos = {}
  }
  local limitations_cache = {}
  local groups_used = {}
  local icons = {}

  -- Defaults
  local lab_default_beacon
  local lab_default_min_belt
  local lab_default_max_belt
  local lab_default_fuel
  local lab_default_cargo_wagon
  local lab_default_fluid_wagon
  local lab_default_disabled_recipes = {}
  local lab_default_min_assembler
  local lab_default_max_assembler
  local lab_default_min_furnace
  local lab_default_max_furnace
  local lab_default_min_drill
  local lab_default_max_drill
  local lab_default_prod_module
  local lab_default_speed_module

  -- Hashes
  local lab_hash_items = {}
  local lab_hash_beacons = {}
  local lab_hash_belts = {}
  local lab_hash_fuels = {}
  local lab_hash_wagons = {}
  local lab_hash_factories = {}
  local lab_hash_modules = {}
  local lab_hash_recipes = {}

  -- Final data collections
  local lab_categories = {}
  local lab_items = {}
  local lab_recipes = {}
  local lab_limitations = {}

  -- Process items
  for _, name in pairs(sorted_item_names) do
    local item = game.item_prototypes[name]
    if item then
      groups_used[item.group.name] = item.group

      local lab_item = {
        id = name,
        name = item_names[name],
        stack = item.stack_size,
        row = get_row(item),
        category = item.group.name
      }

      if item.place_result then
        local entity = item.place_result
        local category = nil

        -- Check and warn for multiple fuel categories
        if entity.burner_prototype then
          local num_categories = 0
          for a, b in pairs(entity.burner_prototype.fuel_categories) do
            num_categories = num_categories + 1
          end
          if num_categories > 1 then
            -- TODO: Allow array of fuel types in data?
            player.print({"factoriolab-export.warn-multiple-fuel-categories", entity.name}, color_warn)
          end
        end

        if entity.type == "transport-belt" then
          lab_item.belt = {speed = entity.belt_speed * 480}
          lab_default_min_belt = compare_default_min(lab_default_min_belt, name, true, entity.belt_speed)
          lab_default_max_belt = compare_default_max(lab_default_max_belt, name, true, entity.belt_speed)
          table.insert(lab_hash_belts, name)
        elseif entity.type == "beacon" then
          lab_item.beacon = entity_utils.get_powered_entity(entity)
          lab_item.beacon.effectivity = entity.distribution_effectivity
          lab_item.beacon.modules = entity.module_inventory_size
          lab_item.beacon.range = entity.supply_area_distance
          if not lab_default_beacon then
            lab_default_beacon = name
          end
          table.insert(lab_hash_beacons, name)
        elseif entity.type == "mining-drill" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.mining = true
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.mining_speed
          if entity.resource_categories["basic-solid"] then
            local is_electric = lab_item.factory.type == "electric"
            lab_default_min_drill = compare_default_min(lab_default_min_drill, name, is_electric, entity.mining_speed)
            lab_default_max_drill = compare_default_max(lab_default_max_drill, name, is_electric, entity.mining_speed)
          end
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "offshore-pump" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.pumping_speed * 60
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "furnace" or entity.type == "assembling-machine" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.crafting_speed
          local is_electric = lab_item.factory.type == "electric"
          if entity.type == "assembling-machine" then
            lab_default_min_assembler =
              compare_default_min(lab_default_min_assembler, name, is_electric, entity.crafting_speed)
            lab_default_max_assembler =
              compare_default_max(lab_default_max_assembler, name, is_electric, entity.crafting_speed)
          elseif entity.type == "furnace" then
            lab_default_min_furnace =
              compare_default_min(lab_default_min_furnace, name, is_electric, entity.crafting_speed)
            lab_default_max_furnace =
              compare_default_max(lab_default_max_furnace, name, is_electric, entity.crafting_speed)
          end
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "lab" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.research = true
          lab_item.factory.speed = entity.researching_speed
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "boiler" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = lab_item.factory.usage -- Speed is based on usage
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "rocket-silo" then
          -- TODO: Account for launch animation energy usage spike
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.crafting_speed
          lab_item.factory.silo = {
            parts = entity.rocket_parts_required,
            launch = entity_utils.launch_ticks(entity)
          }
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "reactor" then
          lab_item.factory = entity_utils.get_powered_entity(entity)
          lab_item.factory.modules = 0
          lab_item.factory.speed = 1
          entity_utils.process_producers(entity, producers)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "cargo-wagon" then
          lab_item.cargoWagon = {
            size = entity.get_inventory_size(defines.inventory.cargo_wagon)
          }
          if not lab_default_cargo_wagon then
            lab_default_cargo_wagon = name
          end
          table.insert(lab_hash_wagons, name)
        elseif entity.type == "fluid-wagon" then
          lab_item.fluidWagon = {
            capacity = entity.fluid_capacity
          }
          if not lab_default_fluid_wagon then
            lab_default_fluid_wagon = name
          end
          table.insert(lab_hash_wagons, name)
        end
      end

      if item.module_effects then
        local effects = item.module_effects
        -- Bonuses seem heavily affected by floating point error for some reason
        -- Round to 4 digits to offset this error
        lab_item.module = {
          consumption = effects.consumption and utils.round(effects.consumption.bonus, 4),
          speed = effects.speed and utils.round(effects.speed.bonus, 4),
          pollution = effects.pollution and utils.round(effects.pollution.bonus, 4),
          productivity = effects.productivity and utils.round(effects.productivity.bonus, 4)
        }

        if item.limitations and #item.limitations > 0 then
          local limitations_serialized = ""
          for _, limitation in pairs(item.limitations) do
            limitations_serialized = limitations_serialized .. limitation
          end
          if limitations_cache[limitations_serialized] then
            lab_item.module.limitation = limitations_cache[limitations_serialized]
          else
            lab_item.module.limitation = name
            lab_limitations[name] = item.limitations
            limitations_cache[limitations_serialized] = name
          end
        end

        lab_default_prod_module =
          compare_default_max(
          lab_default_prod_module,
          name,
          effects.productivity ~= nil,
          (effects.productivity and effects.productivity.bonus) or 0
        )
        lab_default_speed_module =
          compare_default_max(
          lab_default_speed_module,
          name,
          effects.speed ~= nil,
          (effects.speed and effects.speed.bonus) or 0
        )
        table.insert(lab_hash_modules, name)
      end

      if item.fuel_category then
        lab_item.fuel = {
          value = item.fuel_value / 1000000,
          category = item.fuel_category,
          result = item.burnt_result and item.burnt_result.name
        }
        if item.fuel_category == "chemical" then
          local is_resource =
            game.entity_prototypes[name] and game.entity_prototypes[name].resource_category ~= nil or false
          lab_default_fuel = compare_default_max(lab_default_fuel, name, is_resource, item.fuel_value)
        end
        table.insert(lab_hash_fuels, name)
      end

      table.insert(lab_items, lab_item)
      table.insert(lab_hash_items, name)
      local hash_id, scale = utils.get_order_info("item/" .. name)
      add_icon(hash_id, name, scale or 2, "item/" .. name, icons)
    else
      local fluid = game.fluid_prototypes[name]
      if fluid then
        groups_used[fluid.group.name] = fluid.group

        local lab_item = {
          id = name,
          name = fluid_names[name],
          row = get_row(fluid),
          category = fluid.group.name
        }
        table.insert(lab_items, lab_item)
        table.insert(lab_hash_items, name)
        local hash_id, scale = utils.get_order_info("fluid/" .. name)
        add_icon(hash_id, name, scale or 2, "fluid/" .. name, icons)
      else
        player.print({"factoriolab-export.warn-no-item-prototype", item.name}, color_warn)
      end
    end
  end

  -- Process recipes
  for name, recipe in pairs(recipes_enabled) do
    local lab_in = calculate_ingredients(recipe.ingredients)
    local lab_out = calculate_products(recipe.products)
    local lab_recipe = {
      id = name,
      name = recipe_names[name],
      time = recipe.energy,
      ["in"] = lab_in,
      out = lab_out,
      producers = producers.crafting[recipe.category]
    }
    local hash_id, scale = utils.get_order_info("recipe/" .. name)
    if hash_id and hash_id ~= -1 then
      local icon_id = name .. "|recipe"
      lab_recipe.icon = icon_id
      add_icon(hash_id, icon_id, scale or 2, "recipe/" .. name, icons)
    end
    table.insert(lab_recipes, lab_recipe)
    table.insert(lab_hash_recipes, name)
  end

  -- Process 'fake' recipes
  for _, name in pairs(sorted_item_names) do
    local item = game.item_prototypes[name]
    if item then
      -- Check for launch recipe
      if item.rocket_launch_products and #item.rocket_launch_products > 0 then
        for _, silo in pairs(producers.silos) do
          local desired_id = item.rocket_launch_products[1].name
          local backup_id = silo.name .. name .. "-launch"
          local id = check_recipe_name(lab_recipes, desired_id, backup_id, icons)
          local lab_in = {[name] = 1}
          local lab_part
          local fixed_recipe_outputs = calculate_products(game.recipe_prototypes[silo.fixed_recipe].products)
          for id, amount in pairs(fixed_recipe_outputs) do
            lab_in[id] = amount * silo.rocket_parts_required
            lab_part = id
          end
          local lab_out, total = calculate_products(item.rocket_launch_products)
          local lab_recipe = {
            id = id,
            name = item_names[silo.name] .. " : " .. item_names[item.rocket_launch_products[1].name],
            time = 40.6, -- This is later overridden to include launch time in ticks
            ["in"] = lab_in,
            out = lab_out,
            part = lab_part,
            producers = {silo.name}
          }
          table.insert(lab_recipes, lab_recipe)
          table.insert(lab_hash_recipes, id)
          safe_add_recipe_items(lab_recipe, lab_hash_items)
        end
      end
      -- Check for burn recipe
      if item.burnt_result then
        local desired_id = item.burnt_result.name
        local backup_id = name .. "-burn"
        local id = check_recipe_name(lab_recipes, desired_id, backup_id, icons)
        lab_recipe = {
          id = id,
          name = item_names[name] .. " : " .. item_names[item.burnt_result.name],
          time = 1,
          ["in"] = {[name] = 0},
          out = {[item.burnt_result.name] = 0},
          producers = producers.burner[item.fuel_category]
        }
        table.insert(lab_recipes, lab_recipe)
        table.insert(lab_hash_recipes, id)
        safe_add_recipe_items(lab_recipe, lab_hash_items)
      end
    end
    local entity = game.entity_prototypes[name]
    if entity then
      -- Check for resource recipe
      if entity.resource_category then
        local desired_id = name
        local backup_id = name .. "-mining"
        local id = check_recipe_name(lab_recipes, desired_id, backup_id, icons)
        local lab_in = {}
        if entity.mineable_properties.required_fluid then
          local amount = entity.mineable_properties.fluid_amount / 10
          lab_in = {[entity.mineable_properties.required_fluid] = amount}
        end
        local lab_out, total = calculate_products(entity.mineable_properties.products)
        local lab_recipe = {
          id = id,
          name = item_names[name],
          time = entity.mineable_properties.mining_time,
          ["in"] = lab_in,
          out = lab_out,
          producers = producers.resource[entity.resource_category],
          cost = 10000 / total
        }
        -- Allow modules on mining recipes
        -- TODO: Verify whether these limitations actually apply to resource recipes
        for limitation, _ in pairs(lab_limitations) do
          table.insert(lab_limitations[limitation], id)
        end
        table.insert(lab_recipes, lab_recipe)
        table.insert(lab_hash_recipes, id)
        safe_add_recipe_items(lab_recipe, lab_hash_items)
      end
      -- Check for pump recipe
      if entity.type == "offshore-pump" then
        local desired_id = entity.fluid.name
        local backup_id = name .. "-pump"
        local id = check_recipe_name(lab_recipes, desired_id, backup_id, icons)
        local lab_recipe = {
          id = id,
          name = item_names[name] .. " : " .. fluid_names[entity.fluid.name],
          time = 1,
          ["in"] = {},
          out = {[entity.fluid.name] = 1},
          producers = {name},
          cost = 100
        }
        table.insert(lab_recipes, lab_recipe)
        table.insert(lab_hash_recipes, id)
        safe_add_recipe_items(lab_recipe, lab_hash_items)
      end
      -- Check for boiler recipe
      if entity.type == "boiler" then
        local water = game.fluid_prototypes["water"]
        local steam = game.fluid_prototypes["steam"]
        if water and steam then
          -- TODO: Account for different steam temperatures
          if entity.target_temperature == 165 then
            local desired_id = steam.name
            local backup_id = name .. "-boil"
            local id = check_recipe_name(lab_recipes, desired_id, backup_id, icons)

            local temp_diff = 165 - 15
            local energy_reqd = temp_diff * water.heat_capacity / 1000

            local lab_recipe = {
              id = id,
              name = item_names[name] .. " : " .. fluid_names[steam.name],
              time = energy_reqd,
              ["in"] = {[water.name] = 1},
              out = {[steam.name] = 1},
              producers = {name}
            }
            table.insert(lab_recipes, lab_recipe)
            table.insert(lab_hash_recipes, id)
            safe_add_recipe_items(lab_recipe, lab_hash_items)
          end
        else
          player.print({"factoriolab-export.warn-skipping-boiler", name}, color_warn)
        end
      end
    end
  end

  -- Process categories
  for name, group in pairs(groups_used) do
    local lab_category = {
      id = name,
      name = group_names[name]
    }

    table.insert(lab_categories, lab_category)
    local hash_id, scale = utils.get_order_info("item-group/" .. name)
    add_icon(hash_id, name, scale or 0.25, "item-group/" .. name, icons)
  end

  -- Process infinite technology
  local lab_category = {
    id = "research",
    name = gui_names["research"]
  }
  table.insert(lab_categories, lab_category)
  local sprite = "space-science-pack"
  if game.active_mods["space-exploration"] then
    sprite = "se-rocket-science-pack"
  end
  if not game.technology_prototypes[sprite] then
    player.print({"factoriolab-export.warn-no-research-sprite", sprite}, color_warn)
  else
    sprite = "technology/" .. sprite
    local research_hash_id, research_scale = utils.get_order_info(sprite)
    add_icon(research_hash_id, "research", research_scale or 0.25, sprite, icons)
  end
  local tech_col = 0
  local tech_row = 0
  for name, tech in pairs(game.technology_prototypes) do
    if tech.research_unit_count_formula then
      local desired_id = name
      local backup_id = name .. "-technology"
      local id = check_recipe_name(lab_recipes, desired_id, backup_id, {})
      local hash_id, scale = utils.get_order_info("technology/" .. name)
      add_icon(hash_id, id, scale or 0.25, "technology/" .. name, icons)
      local lab_item = {
        id = id,
        name = technology_names[name],
        category = "research",
        stack = 200,
        row = tech_row
      }
      table.insert(lab_items, lab_item)
      -- Allow modules on research recipes
      for limitation, _ in pairs(lab_limitations) do
        table.insert(lab_limitations[limitation], id)
      end
      local lab_recipe = {
        id = id,
        name = technology_names[name],
        time = tech.research_unit_energy / 60,
        ["in"] = calculate_ingredients(tech.research_unit_ingredients),
        out = {[id] = 1},
        producers = producers.labs
      }
      table.insert(lab_recipes, lab_recipe)
      table.insert(lab_hash_recipes, id)
      safe_add_recipe_items(lab_recipe, lab_hash_items)
      tech_col = tech_col + 1
      if tech_col == 10 then
        tech_row = tech_row + 1
        tech_col = 0
      end
    end
  end

  local filtered_recipes = {}
  -- Check recipes have producers
  for _, lab_recipe in pairs(lab_recipes) do
    if lab_recipe.producers and #lab_recipe.producers > 0 then
      table.insert(filtered_recipes, lab_recipe)
    else
      player.print({"factoriolab-export.warn-skipping-no-producer", lab_recipe.id}, color_warn)
    end

    -- Disable recipes that cause unnecessary circular loops
    local disable = false

    -- [Vanilla] Disable barrel emptying recipes
    if string.find(lab_recipe.id, "^empty%-.+%-barrel$") then
      disable = true
    end

    -- [IR2] Disable scrapping recipes
    if game.active_mods["IndustrialRevolution"] and string.find(lab_recipe.id, "^scrap%-") then
      disable = true
    end

    -- [SXP] Disable delivery cannon recipes
    if
      game.active_mods["space-exploration"] and
        (string.find(lab_recipe.id, "^se%-delivery%-cannon%-pack%-") or
          string.find(lab_recipe.id, "^se%-delivery%-cannon%-weapon%-pack%-"))
     then
      disable = true
    end

    -- [ANG] Disable void recipes
    if game.active_mods["angelsrefining"] and string.find(lab_recipe.id, "^void%-") then
      disable = true
    end

    -- [NLS] Disable unboxing recipes
    if game.active_mods["nullius"] and string.find(lab_recipe.id, "^nullius%-unbox%-") then
      disable = true
    end

    if disable then
      table.insert(lab_default_disabled_recipes, lab_recipe.id)
    end
  end
  lab_recipes = filtered_recipes

  game.remove_path(folder)
  local pretty_json = player_settings["factoriolab-export-pretty-json"].value

  if language ~= "en" then
    -- Build I18n data ONLY for non-English
    lab_i18n = {
      categories = utils.to_table(lab_categories),
      items = utils.to_table(lab_items),
      recipes = utils.to_table(lab_recipes)
    }

    game.write_file(folder .. "i18n/" .. language .. ".json", json.stringify(lab_i18n, pretty_json))
    player.print({"factoriolab-export.complete-i18n", language}, color_good)
    return
  end

  -- Process and generate sprite for scaled icons
  local lab_icons = {}
  local sprite_surface = game.create_surface("lab-sprite")

  local x = 0
  local y = 0
  for _, icon in pairs(icons) do
    rendering.draw_sprite(
      {
        sprite = icon.sprite,
        -- TODO: Check for layers out of bounds in data-final-fixes.lua
        x_scale = icon.scale,
        y_scale = icon.scale,
        target = {x = x, y = y},
        surface = sprite_surface
      }
    )
    local lab_icon = {
      id = icon.name,
      color = "#000000",
      position = string.format("%spx %spx", x > 0 and (x / 2) * -64 or 0, y > 0 and (y / 2) * -64 or 0)
    }
    table.insert(lab_icons, lab_icon)
    for _, copy in pairs(icon.copies) do
      local lab_icon_copy = {
        id = copy,
        color = "#000000",
        position = lab_icon.position
      }
      table.insert(lab_icons, lab_icon_copy)
    end
    x = x + 2
    if x == 32 then
      y = y + 2
      x = 0
    end
  end

  if x == 0 then
    y = y - 2
  end

  local rows = (y / 2) + 1
  local y_resolution = rows * 64
  local y_position = rows - 1

  game.take_screenshot(
    {
      player = player,
      by_player = player,
      surface = sprite_surface,
      position = {15, y_position},
      resolution = {1024, y_resolution},
      zoom = 1,
      quality = 100,
      daytime = 1,
      path = folder .. "icons.png",
      show_gui = false,
      show_entity_info = false,
      anti_alias = false
    }
  )

  local version = {}
  for name, ver in pairs(game.active_mods) do
    if name ~= "factoriolab-export" and name ~= "flib" then
      version[name] = ver
    end
  end

  -- Safely build arrays for defaults
  lab_default_min_factory_rank = {}
  if lab_default_min_assembler then
    table.insert(lab_default_min_factory_rank, lab_default_min_assembler[1])
  end
  if lab_default_min_furnace then
    table.insert(lab_default_min_factory_rank, lab_default_min_furnace[1])
  end
  if lab_default_min_drill then
    table.insert(lab_default_min_factory_rank, lab_default_min_drill[1])
  end

  lab_default_max_factory_rank = {}
  if lab_default_max_assembler then
    table.insert(lab_default_max_factory_rank, lab_default_min_assembler[1])
  end
  if lab_default_max_furnace then
    table.insert(lab_default_max_factory_rank, lab_default_max_furnace[1])
  end
  if lab_default_max_drill then
    table.insert(lab_default_max_factory_rank, lab_default_max_drill[1])
  end

  lab_default_module_rank = {}
  if lab_default_prod_module then
    table.insert(lab_default_module_rank, lab_default_prod_module[1])
  end
  if lab_default_speed_module then
    table.insert(lab_default_module_rank, lab_default_speed_module[1])
  end

  lab_data = {
    version = version,
    categories = lab_categories,
    icons = lab_icons,
    items = lab_items,
    limitations = lab_limitations,
    recipes = lab_recipes,
    defaults = {
      beacon = lab_default_beacon,
      minBelt = lab_default_min_belt and lab_default_min_belt[1],
      maxBelt = lab_default_max_belt and lab_default_max_belt[1],
      fuel = lab_default_fuel and lab_default_fuel[1],
      cargoWagon = lab_default_cargo_wagon,
      fluidWagon = lab_default_fluid_wagon,
      disabledRecipes = lab_default_disabled_recipes,
      minFactoryRank = lab_default_min_factory_rank,
      maxFactoryRank = lab_default_max_factory_rank,
      moduleRank = lab_default_module_rank,
      beaconModule = lab_default_speed_module and lab_default_speed_module[1]
    }
  }

  lab_hash = {
    items = lab_hash_items,
    beacons = lab_hash_beacons,
    belts = lab_hash_belts,
    fuels = lab_hash_fuels,
    wagons = lab_hash_wagons,
    factories = lab_hash_factories,
    modules = lab_hash_modules,
    recipes = lab_hash_recipes
  }

  game.write_file(folder .. "data.json", json.stringify(lab_data, pretty_json))
  game.write_file(folder .. "hash.json", json.stringify(lab_hash, pretty_json))
  player.print({"factoriolab-export.complete-data"}, color_good)
end
