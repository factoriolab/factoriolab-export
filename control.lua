local dictionary = require("__flib__.dictionary")
local event = require("__flib__.event")

require("json")
require("utils")

local folder = "lab-export/"
local player
local player_settings
local dictionaries
local language

local function process_technology()
  local recipes_unlocked = {}
  for _, technology in pairs(game.technology_prototypes) do
    local effects = technology.effects
    if effects then
      for _, effect in pairs(effects) do
        if effect and effect.type == "unlock-recipe" then
          recipes_unlocked[effect.recipe] = true
        end
      end
    end
  end
  return recipes_unlocked
end

local function process_recipes(recipes_unlocked)
  local recipes_enabled = {}
  for name, recipe in pairs(game.recipe_prototypes) do
    local include = true

    -- Skip recipes that cause unnecessary circular loops
    -- [Vanilla] Ignore barrel emptying recipes
    local empty = string.find(name, "^empty%-.+%-barrel$")
    if empty then
      include = false
    end

    -- Skip recipes that are not unlocked / enabled
    if recipe.enabled == false and not recipes_unlocked[name] then
      include = false
    end

    -- Skip recipes that are hidden other than fixed recipes (silo)
    local fixed_recipe = false
    for _, entity in pairs(game.entity_prototypes) do
      if (entity.fixed_recipe == name) then
        fixed_recipe = true
      end
    end
    if recipe.hidden == true and not fixed_recipe then
      include = false
    end

    if include then
      recipes_enabled[name] = recipe
    end
  end
  return recipes_enabled
end

local function process_items(recipes_enabled)
  local items_used = {}

  -- Check for burnt result / rocket launch product
  for name, item in pairs(game.item_prototypes) do
    if #item.rocket_launch_products > 0 then
      items_used[name] = true
      for product_name, product in pairs(item.rocket_launch_products) do
        items_used[product.name] = true
      end
    end

    if item.burnt_result then
      items_used[name] = true
      items_used[item.burnt_result.name] = true
    end
  end

  -- Check for recipe input / output
  for name, recipe in pairs(recipes_enabled) do
    -- Check ingredients
    for _, ingredient in pairs(recipe.ingredients) do
      if ingredient then
        items_used[ingredient.name] = true
      end
    end

    -- Check products
    for _, product in pairs(recipe.products) do
      if product then
        items_used[product.name] = true
      end
    end
  end

  return items_used
end

local function get_stored_size(entity)
  return tonumber(string.match(entity.order, ".-|(%d+)"))
end

local function convert_emissions(emissions, energy)
  if not emissions or not energy then
    return nil
  end
  return emissions * energy * 1000 * 60
end

local function get_fuel_category(entity)
  local category = nil
  for fuel_category, _ in pairs(entity.burner_prototype.fuel_categories) do
    if category == nil then
      category = fuel_category
    else
      -- TODO: Allow array of fuel types in data?
      player.print({"lab-export.warn-multiple-fuel-categories", entity.name})
      break
    end
  end
  return category
end

local function base_powered_entity(entity)
  local energy_type = nil
  local fuel_category = nil
  local energy_usage = nil
  local energy_drain = nil
  local pollution = nil

  if entity.type == "boiler" or entity.type == "reactor" then
    energy_usage = utils.convert_energy(entity.max_energy_usage)
  else
    energy_usage = utils.convert_energy(entity.energy_usage)
  end

  if entity.electric_energy_source_prototype ~= nil then
    energy_type = "electric"
    energy_drain = utils.convert_energy(entity.electric_energy_source_prototype.drain)
    pollution = convert_emissions(entity.electric_energy_source_prototype.emissions, energy_usage)
  elseif entity.burner_prototype ~= nil then
    energy_type = "burner"
    fuel_category = get_fuel_category(entity)
    pollution = convert_emissions(entity.burner_prototype.emissions, energy_usage)
  end

  return {
    category = fuel_category,
    drain = energy_drain,
    pollution = pollution,
    type = energy_type,
    usage = energy_usage
  }
end

local function sort_items(items_used)
  local items_list = {}
  for name, _ in pairs(items_used) do
    local item = game.item_prototypes[name] or game.fluid_prototypes[name]
    table.insert(
      items_list,
      {item, item.name, item.order, item.subgroup.name, item.subgroup.order, item.group.name, item.group.order}
    )
  end

  utils.sort_by(items_list, 7, 6, 5, 4, 3, 2)

  local sorted_item_names = {}
  for i = 1, #items_list do
    table.insert(sorted_item_names, items_list[i][2])
  end
  return sorted_item_names
end

local function check_recipe_name(recipes, desired_id, backup_id, copied_icons)
  for _, recipe in pairs(recipes) do
    if recipe.id == desired_id then
      if not copied_icons[desired_id] then
        copied_icons[desired_id] = {}
      end
      table.insert(copied_icons[desired_id], backup_id)
      return backup_id
    end
  end
  return desired_id
end

local function process_producers(entity, producers)
  local producer_categories

  if entity.type == "mining-drill" then
    producer_categories = entity.resource_categories
  else
    producer_categories = entity.crafting_categories
  end

  for category, _ in pairs(producer_categories) do
    if not producers[category] then
      producers[category] = {}
    end
    table.insert(producers[category], entity.name)
  end
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
local last_row = 0, last_group, last_subgroup
local function get_row(item)
  if item.group == last_group then
    if item.subgroup == last_subgroup then
    else
      last_row = last_row + 1
    end
  else
    last_row = 0
  end
  last_group = item.group
  last_subgroup = item.subgroup
  return last_row
end

local function export_data(e)
  player.print({"lab-export.initialize"})

  -- Localized names
  local group_names = dictionaries["item_group_names"]
  local item_names = dictionaries["item_names"]
  local fluid_names = dictionaries["fluid_names"]
  local recipe_names = dictionaries["recipe_names"]
  local technology_names = dictionaries["technology_names"]
  local gui_names = dictionaries["gui_technology_names"]

  -- Temp collections
  local recipes_unlocked = process_technology()
  local recipes_enabled = process_recipes(recipes_unlocked)
  local items_used = process_items(recipes_enabled)
  local sorted_item_names = sort_items(items_used)
  local producers = {}
  local tech_producers = {}
  local limitations_cache = {}
  local groups_used = {}
  local scaled_icons = {}
  local copied_icons = {}
  local rocket_silos = {}

  -- Defaults
  local lab_default_beacon
  local lab_default_min_belt
  local lab_default_max_belt
  local lab_default_fuel
  local lab_default_cargo_wagon
  local lab_default_fluid_wagon
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
        if entity.type == "transport-belt" then
          lab_item.belt = {speed = entity.belt_speed * 480}
          lab_default_min_belt = compare_default_min(lab_default_min_belt, name, true, entity.belt_speed)
          lab_default_max_belt = compare_default_max(lab_default_max_belt, name, true, entity.belt_speed)
          table.insert(lab_hash_belts, name)
        elseif entity.type == "beacon" then
          lab_item.beacon = base_powered_entity(entity)
          lab_item.beacon.effectivity = entity.distribution_effectivity
          lab_item.beacon.modules = entity.module_inventory_size
          lab_item.beacon.range = entity.supply_area_distance
          if not lab_default_beacon then
            lab_default_beacon = name
          end
          table.insert(lab_hash_beacons, name)
        elseif entity.type == "mining-drill" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.mining = true
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.mining_speed
          process_producers(entity, producers)
          if entity.resource_categories["basic-solid"] then
            local is_electric = lab_item.factory.type == "electric"
            lab_default_min_drill = compare_default_min(lab_default_min_drill, name, is_electric, entity.mining_speed)
            lab_default_max_drill = compare_default_max(lab_default_max_drill, name, is_electric, entity.mining_speed)
          end
          table.insert(lab_hash_factories, name)
        elseif entity.type == "offshore-pump" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.pumping_speed * 60
          table.insert(lab_hash_factories, name)
        elseif entity.type == "furnace" or entity.type == "assembling-machine" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.crafting_speed
          process_producers(entity, producers)
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
          table.insert(lab_hash_factories, name)
        elseif entity.type == "lab" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.research = true
          lab_item.factory.speed = entity.researching_speed
          table.insert(tech_producers, name)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "boiler" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = lab_item.factory.usage -- Speed is based on usage
          table.insert(lab_hash_factories, name)
        elseif entity.type == "rocket-silo" then
          -- TODO: Account for launch animation energy usage spike
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = entity.module_inventory_size
          lab_item.factory.speed = entity.crafting_speed

          -- Calculate number of ticks for launch
          -- Based on https://github.com/ClaudeMetz/FactoryPlanner/blob/master/modfiles/data/handlers/generator_util.lua#L335
          local ticks = 2435 -- Default to vanilla rocket silo animation ticks
          local rocket = entity.rocket_entity_prototype

          local rocket_flight_threshold = 0.5
          local launch_steps = {
            lights_blinking_open = (1 / entity.light_blinking_speed) + 1,
            doors_opening = (1 / entity.door_opening_speed) + 1,
            doors_opened = entity.rocket_rising_delay + 1,
            rocket_rising = (1 / rocket.rising_speed) + 1,
            rocket_ready = 14, -- Estimate for satellite insertion delay
            launch_started = entity.launch_wait_time + 1,
            engine_starting = (1 / rocket.engine_starting_speed) + 1,
            -- This calculates a fractional amount of ticks. Also, math.log(x) calculates the natural logarithm
            rocket_flying = math.log(1 + rocket_flight_threshold * rocket.flying_acceleration / rocket.flying_speed) /
              math.log(1 + rocket.flying_acceleration),
            lights_blinking_close = (1 / entity.light_blinking_speed) + 1,
            doors_closing = (1 / entity.door_opening_speed) + 1
          }

          local ticks = 0
          for _, ticks_taken in pairs(launch_steps) do
            ticks = ticks + ticks_taken
          end
          ticks = math.floor(ticks + 0.5)

          lab_item.factory.silo = {
            parts = entity.rocket_parts_required,
            launch = ticks
          }

          process_producers(entity, producers)
          table.insert(rocket_silos, entity)
          table.insert(lab_hash_factories, name)
        elseif entity.type == "reactor" then
          lab_item.factory = base_powered_entity(entity)
          lab_item.factory.modules = 0
          lab_item.factory.speed = 1
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
        local is_resource =
          game.entity_prototypes[name] and game.entity_prototypes[name].resource_category ~= nil or false
        lab_default_fuel = compare_default_max(lab_default_fuel, name, is_resource, item.fuel_value)
        table.insert(lab_hash_fuels, name)
      end

      table.insert(lab_items, lab_item)
      table.insert(lab_hash_items, name)
      table.insert(scaled_icons, {name = name, sprite = "item/" .. name, scale = 2})
    else
      local fluid = game.fluid_prototypes[name]
      if fluid then
        groups_used[fluid.group.name] = fluid.group
        local row = get_row(fluid)

        local lab_item = {
          id = name,
          name = fluid_names[name],
          row = get_row(fluid),
          category = fluid.group.name
        }
        table.insert(lab_items, lab_item)
        table.insert(scaled_icons, {name = name, sprite = "fluid/" .. name, scale = 2})
      else
        player.print({"lab-export.warn-no-item-prototype", item.name})
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
      producers = producers[recipe.category]
    }
    table.insert(lab_recipes, lab_recipe)
    table.insert(lab_hash_recipes, name)
    if game.item_prototypes[name] == nil and game.fluid_prototypes[name] == nil then
      -- TODO: Detect if this recipe icon differs from item / fluid icon and then use it instead
      table.insert(scaled_icons, {name = name, sprite = "recipe/" .. name, scale = 2})
    end
  end

  -- Process 'fake' recipes
  for _, name in pairs(sorted_item_names) do
    local item = game.item_prototypes[name]
    if item then
      -- Check for launch recipe
      if item.rocket_launch_products and #item.rocket_launch_products > 0 then
        for _, silo in pairs(rocket_silos) do
          local desired_id = item.rocket_launch_products[1].name
          local backup_id = silo.name .. name .. "-launch"
          local id = check_recipe_name(lab_recipes, desired_id, backup_id, copied_icons)
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
        end
      end
      -- Check for burn recipe
      if item.burnt_result then
        local burn_producers = {}
        for _, producer in pairs(game.entity_prototypes) do
          if producer.burner_prototype then
            if producer.burner_prototype.fuel_categories[item.fuel_category] then
              table.insert(burn_producers, producer.name)
            end
          end
        end
        if #burn_producers > 0 then
          local desired_id = item.burnt_result.name
          local backup_id = name .. "-burn"
          local id = check_recipe_name(lab_recipes, desired_id, backup_id, copied_icons)
          lab_recipe = {
            id = id,
            name = item_names[name] .. " : " .. item_names[item.burnt_result.name],
            time = 1,
            ["in"] = {[name] = 0},
            out = {[item.burnt_result.name] = 0},
            producers = burn_producers
          }
          table.insert(lab_recipes, lab_recipe)
        else
          player.print({"lab-export.warn-skipping-burn", name})
        end
      end
    end
    local entity = game.entity_prototypes[name]
    if entity then
      -- Check for resource recipe
      if entity.resource_category then
        local desired_id = name
        local backup_id = name .. "-mining"
        local id = check_recipe_name(lab_recipes, desired_id, backup_id, copied_icons)
        local lab_in
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
          producers = producers[entity.resource_category],
          cost = 10000 / total
        }
        -- Allow modules on mining recipes
        -- TODO: Verify whether these limitations actually apply to resource recipes
        for limitation, _ in pairs(lab_limitations) do
          table.insert(lab_limitations[limitation], id)
        end
        table.insert(lab_recipes, lab_recipe)
      end
      -- Check for pump recipe
      if entity.type == "offshore-pump" then
        local desired_id = entity.fluid.name
        local backup_id = name .. "-pump"
        local id = check_recipe_name(lab_recipes, desired_id, backup_id, copied_icons)
        local lab_recipe = {
          id = id,
          name = item_names[name] .. " : " .. fluid_names[entity.fluid.name],
          time = 1,
          out = {[entity.fluid.name] = 1},
          producers = {name},
          cost = 100
        }
        table.insert(lab_recipes, lab_recipe)
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
            local id = check_recipe_name(lab_recipes, desired_id, backup_id, copied_icons)

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
          end
        else
          player.print({"lab-export.warn-skipping-boiler", name})
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
    local size = get_stored_size(group)
    local scale = 64 / size
    table.insert(lab_categories, lab_category)
    table.insert(scaled_icons, {name = name, sprite = "item-group/" .. name, scale = scale})
  end

  -- Process infinite technology
  local lab_category = {
    id = "research",
    name = gui_names["research"]
  }
  table.insert(lab_categories, lab_category)
  table.insert(scaled_icons, {name = "infinite-research", sprite = "technology/space-science-pack", scale = 0.25})
  local tech_col = 0
  local tech_row = 0
  for name, tech in pairs(game.technology_prototypes) do
    if tech.research_unit_count_formula then
      table.insert(scaled_icons, {name = name, sprite = "technology/" .. name, scale = 0.25})
      local lab_item = {
        id = name,
        name = technology_names[name],
        category = "research",
        stack = 200,
        row = tech_row
      }
      table.insert(lab_items, lab_item)
      -- Allow modules on research recipes
      for limitation, _ in pairs(lab_limitations) do
        table.insert(lab_limitations[limitation], name)
      end
      local lab_recipe = {
        id = name,
        name = technology_names[name],
        time = tech.research_unit_energy / 60,
        ["in"] = calculate_ingredients(tech.research_unit_ingredients),
        out = {[name] = 1},
        producers = tech_producers
      }
      table.insert(lab_recipes, lab_recipe)
      tech_col = tech_col + 1
      if tech_col == 10 then
        tech_row = tech_row + 1
        tech_col = 0
      end
    end
  end

  game.remove_path(folder)
  local pretty_json = player_settings["lab-export-pretty-json"].value

  if language ~= "en" then
    -- Build I18n data ONLY for non-English
    lab_i18n = {
      categories = utils.to_table(lab_categories),
      items = utils.to_table(lab_items),
      recipes = utils.to_table(lab_recipes)
    }

    game.write_file(folder .. "i18n/" .. language .. ".json", json.stringify(lab_i18n, pretty_json))
    player.print({"lab-export.complete-i18n", language})
    return
  end

  -- Process and generate sprite for scaled icons
  local lab_icons = {}
  local sprite_surface = game.create_surface("lab-sprite")

  local x = 0
  local y = 0
  for _, icon in pairs(scaled_icons) do
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
      color = "#000000", -- TODO: Find some way to determine average color? Or use external tool?
      position = string.format("%spx %spx", x > 0 and (x / 2) * -64 or 0, y > 0 and (y / 2) * -64 or 0)
    }
    table.insert(lab_icons, lab_icon)
    if copied_icons[icon.name] then
      for _, copy in pairs(copied_icons[icon.name]) do
        lab_icon.id = copy
        table.insert(lab_icons, lab_icon)
      end
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

  lab_data = {
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
      disabledRecipes = {},
      minFactoryRank = {
        lab_default_min_assembler and lab_default_min_assembler[1],
        lab_default_min_furnace and lab_default_min_furnace[1],
        lab_default_min_drill and lab_default_min_drill[1]
      },
      maxFactoryRank = {
        lab_default_max_assembler and lab_default_max_assembler[1],
        lab_default_max_furnace and lab_default_max_furnace[1],
        lab_default_max_drill and lab_default_max_drill[1]
      },
      moduleRank = {
        lab_default_prod_module and lab_default_prod_module[1],
        lab_default_speed_module and lab_default_speed_module[1]
      },
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
  player.print({"lab-export.complete-data"})
end

local function create_dictionaries()
  for _, type in pairs({"entity", "fluid", "item", "item_group", "recipe", "technology"}) do
    -- If the object's name doesn't have a translation, use its internal name as the translation
    local Names = dictionary.new(type .. "_names", true)
    for name, prototype in pairs(game[type .. "_prototypes"]) do
      Names:add(name, prototype.localised_name)
    end
  end
  local GuiNames = dictionary.new("gui_technology_names", true)
  GuiNames:add("research", {"gui-technology-progress.title"})
end

event.on_init(
  function()
    dictionary.init()
    create_dictionaries()
  end
)

event.on_player_created(
  function(e)
    player = game.players[e.player_index]
    player_settings = settings.get_player_settings(player)
    if player_settings["lab-export-disable"].value then
      log("skipping data export")
      return
    end
    dictionary.translate(player)
  end
)

event.on_string_translated(
  function(e)
    local language_data = dictionary.process_translation(e)
    if language_data then
      for _, player_index in pairs(language_data.players) do
        dictionaries = language_data.dictionaries
        language = language_data.language
        export_data(e)
      end
    end
  end
)
