local state = require("state")
local utils = require("utils")

local entities = {}

function entities.item(localised_strings, entity)
  local sprite = "entity/" .. entity.name
  local item = {
    id = entity.name,
    icon = sprite,
    row = 0,
    category = "entity"
  }
  table.insert(state.data.items, item)
  table.insert(state.icons, {sprite = sprite, scale = 2})
  table.insert(localised_strings, entity.localised_name)
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

local function machine_speed(entity, quality)
  if utils.is_crafting_machine(entity) then
    return entity.get_crafting_speed(quality)
  elseif entity.type == "lab" then
    return entity.get_researching_speed(quality) or 1
  elseif entity.type == "mining-drill" then
    return entity.mining_speed or 1
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

local function machine_silo(entity)
  return nil
end

local function machine_base_effect(entity)
  return entity.effect_receiver and entity.effect_receiver.base_effect or nil
end

local function machine_hide_rate(entity)
  return entity.type == "asteroid-collector" or nil
end

local function machine_total_recipe(entity)
  return entity.type == "agricultural-tower" or nil
end

local function machine_ingredient_usage(entity)
  local percent = entity.science_pack_drain_rate_percent
  if not percent or percent == 100 then
    return nil
  end

  return percent / 100
end

function entities.machine(entity)
  local machine = {
    speed = machine_speed(entity),
    modules = utils.modules(entity),
    disallowedEffects = utils.disallowed_effects(entity),
    type = utils.energy_type(entity),
    fuelCategories = machine_fuel_categories(entity),
    usage = utils.usage(entity),
    drain = utils.drain(entity),
    pollution = utils.pollution(entity),
    silo = machine_silo(entity),
    size = utils.size(entity),
    baseEffect = machine_base_effect(entity),
    hideRate = machine_hide_rate(entity),
    totalRecipe = machine_total_recipe(entity),
    entityType = entity.type,
    locations = utils.locations(entity),
    ingredientUsage = machine_ingredient_usage(entity)
  }

  -- TODO: Qualities?
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

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    machine.qualityRecord = quality_record
  end

  return machine
end

function entities.cargo_wagon(entity)
  local wagon = {
    size = entity.get_inventory_size(defines.inventory.cargo_wagon)
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local size = entity.get_inventory_size(defines.inventory.cargo_wagon, name)
    if wagon.size ~= size then
      variant.size = size
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    wagon.qualityRecord = quality_record
  end

  return wagon
end

function entities.fluid_wagon(entity)
  local wagon = {
    capacity = entity.get_fluid_capacity()
  }

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local capacity = entity.get_fluid_capacity(name)
    if wagon.capacity ~= capacity then
      variant.capacity = capacity
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    wagon.qualityRecord = quality_record
  end

  return wagon
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
