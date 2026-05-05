local recipes = require("recipes")
local state = require("state")
local utils = require("utils")

local entities = {}

function entities.item(entity)
  local sprite = "entity/" .. entity.name
  local item = {
    id = "entity-" .. entity.name,
    icon = sprite
  }
  table.insert(state.items_meta, {item = item, sprite = sprite, scale = 2, proto = entity})
  state.item_map[item.id] = item
  state.items_used[item.id] = true
  return item
end

function entities.beacon(entity)
  local beacon = {
    effectivity = entity.distribution_effectivity,
    modules = utils.modules(entity),
    range = entity.get_supply_area_distance(),
    type = utils.energy_type(entity),
    usage = utils.usage(entity),
    disallowedEffects = utils.disallowed_effects(entity),
    size = utils.size(entity),
    profile = entity.profile
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    if entity.distribution_effectivity_bonus_per_quality_level then
      variant.effectivity = beacon.effectivity + quality.level * entity.distribution_effectivity_bonus_per_quality_level
    end

    local modules = utils.modules(entity, quality)
    if modules ~= beacon.modules then
      variant.modules = modules
    end

    local range = entity.get_supply_area_distance(name)
    if range ~= beacon.range then
      variant.range = range
    end

    local usage = utils.usage(entity, name)
    if usage ~= beacon.usage then
      variant.usage = usage
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    beacon.qualityRecord = quality_record
  end

  return beacon
end

function entities.belt(entity)
  return {speed = entity.belt_speed * 8 * 60}
end

function entities.pipe(entity)
  local speed_num = entity.get_pumping_speed()
  local pipe = {
    speed = speed_num * 60
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local speed = entity.get_pumping_speed(name)
    if speed ~= speed_num then
      variant.speed = speed * 60
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    pipe.qualityRecord = quality_record
  end

  return pipe
end

local function output_fluid(entity)
  for _, fluid_box in ipairs(entity.fluidbox_prototypes) do
    if fluid_box.filter and fluid_box.production_type == "output" then
      return fluid_box.filter.name
    end
  end
end

local function input_fluid(entity)
  for _, fluid_box in ipairs(entity.fluidbox_prototypes) do
    if fluid_box.filter and fluid_box.production_type == "input" then
      return fluid_box.filter.name
    end
  end
end

local function machine_speed(entity, quality)
  if utils.is_crafting_machine(entity) then
    return entity.get_crafting_speed(quality)
  elseif entity.type == "lab" then
    return entity.get_researching_speed(quality) or 1
  elseif entity.type == "mining-drill" then
    return entity.mining_speed or 1
  elseif entity.type == "offshore-pump" then
    return entity.get_pumping_speed(quality) * 60
  elseif entity.type == "boiler" then
    local usage = utils.usage(entity, quality)
    local input = input_fluid(entity)
    local fluid = prototypes.fluid[input]
    local diff = entity.target_temperature - fluid.default_temperature
    local energy = diff * fluid.heat_capacity / 1000
    return usage / energy
  else
    return 1
  end
end

local function machine_fuel_categories(entity)
  -- TODO: Handle heat_energy_source_prototype, fluid_energy_source_prototype
  if not entity.burner_prototype or not entity.burner_prototype.fuel_categories then
    return nil
  end

  local fuel_categories = {}

  for name, _ in pairs(entity.burner_prototype.fuel_categories) do
    table.insert(fuel_categories, name)
  end

  return fuel_categories
end

local function pollution(energy_source, usage)
  local result = energy_source.emissions_per_joule["pollution"] * usage * 60 * 60
  return result > 0 and result or nil
end

local function machine_pollution(entity, quality)
  local energy_source =
    entity.electric_energy_source_prototype or entity.burner_prototype or entity.heat_energy_source_prototype or
    entity.fluid_energy_source_prototype or
    entity.void_energy_source_prototype
  local usage = entity.get_max_energy_usage(quality)
  local result = energy_source.emissions_per_joule["pollution"] * usage * 60 * 60
  return result > 0 and result or nil
end

local function machine_silo(entity)
  if entity.type ~= "rocket-silo" then
    return nil
  end

  return {
    parts = entity.rocket_parts_required,
    launch = 0
  }
end

local function machine_base_effect(entity)
  return entity.effect_receiver and entity.effect_receiver.base_effect or nil
end

local function machine_ingredient_usage(entity)
  local percent = entity.science_pack_drain_rate_percent
  if not percent or percent == 100 then
    return nil
  end

  return percent / 100
end

local function add_producers(id, categories, type)
  for category, _ in pairs(categories) do
    if not state.producers[type][category] then
      state.producers[type][category] = {id}
    else
      table.insert(state.producers[type][category], id)
    end
  end
end

local function process_producers(entity, item)
  if entity.crafting_categories then
    add_producers(item.id, entity.crafting_categories, "crafting")
  end

  if entity.resource_categories then
    add_producers(item.id, entity.resource_categories, "resource")
    if #entity.fluidbox_prototypes > 0 then
      add_producers(item.id, entity.resource_categories, "resource_fluid")
    end
  end

  if entity.burner_prototype then
    add_producers(item.id, entity.burner_prototype.fuel_categories, "burner")
  end

  if entity.type == "offshore-pump" then
    state.machines.offshore_pump[entity.name] = {id = item.id, output = output_fluid(entity)}
  elseif entity.type == "boiler" then
    state.machines.boiler[entity.name] = {id = item.id, output = output_fluid(entity), input = input_fluid(entity)}
  elseif entity.type == "rocket-silo" then
    -- TODO: Handle silos without fixed part recipes?
    if entity.fixed_recipe then
      local recipe = prototypes.recipe[entity.fixed_recipe]
      local out, catalyst, total = recipes.products(recipe.products)
      local part
      local recipe_in = {}
      for item_id, amount in pairs(out) do
        part = item_id
        recipe_in[item_id] = out[item_id] * entity.rocket_parts_required
      end

      if part then
        state.machines.silo[entity.name] = {id = item.id, part = part, recipe_in = recipe_in}
      end
    end
  elseif entity.type == "lab" then
    table.insert(state.machines.lab, item.id)
  end
end

function entities.machine(entity, item)
  local usage = utils.usage(entity)
  local machine = {
    speed = machine_speed(entity),
    modules = utils.modules(entity),
    disallowedEffects = utils.disallowed_effects(entity),
    type = utils.energy_type(entity),
    fuelCategories = machine_fuel_categories(entity),
    usage = utils.usage(entity),
    drain = utils.drain(entity),
    pollution = machine_pollution(entity),
    silo = machine_silo(entity),
    size = utils.size(entity),
    baseEffect = machine_base_effect(entity),
    entityType = entity.type,
    locations = utils.locations(entity),
    ingredientUsage = machine_ingredient_usage(entity)
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local speed = machine_speed(entity, name)
    if speed ~= machine.speed then
      variant.speed = speed
    end

    local modules = utils.modules(entity, quality)
    if modules ~= machine.modules then
      variant.modules = modules
    end

    local usage = utils.usage(entity, name)
    if usage ~= machine.usage then
      variant.usage = usage
    end

    local pollution = machine_pollution(entity, name)
    if pollution ~= machine.pollution then
      variant.pollution = pollution
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    machine.qualityRecord = quality_record
  end

  process_producers(entity, item)
  if entity.fixed_recipe then
    state.recipes_fixed[entity.fixed_recipe] = true
  end

  return machine
end

function entities.cargo_wagon(entity)
  return {
    size = entity.get_inventory_size(defines.inventory.cargo_wagon)
  }
end

function entities.fluid_wagon(entity)
  return {
    capacity = entity.get_fluid_capacity()
  }
end

function inserter_speed(entity, quality)
  local rotations_per_tick = entity.get_inserter_rotation_speed(quality)
  local ticks_per_rotation = math.floor(1 / rotations_per_tick / 2) * 2
  local rotations_per_sec = 1 / ticks_per_rotation * 60
  local degrees_per_sec = rotations_per_sec * 360
  return degrees_per_sec
end

function entities.inserter(entity)
  local inserter = {
    speed = inserter_speed(entity),
    stack = entity.inserter_stack_size_bonus,
    category = entity.bulk and "bulk" or nil,
    ignoresBonus = entity.uses_inserter_stack_size_bonus == false and true or nil
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local speed = inserter_speed(entity, name)
    if inserter.speed ~= speed then
      variant.speed = speed
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    inserter.qualityRecord = quality_record
  end

  return inserter
end

return entities
