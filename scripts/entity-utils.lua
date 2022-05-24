local utils = require("utils")

local entity_utils = {}

local function convert_emissions(emissions, energy)
  if not emissions or not energy then
    return nil
  end
  return emissions * energy * 1000 * 60
end

local function get_fuel_category(entity, player)
  local category = nil
  for fuel_category, _ in pairs(entity.burner_prototype.fuel_categories) do
    if category == nil then
      category = fuel_category
    else
      -- TODO: Allow array of fuel types in data?
      player.print({"factorio-lab-export.warn-multiple-fuel-categories", entity.name})
      break
    end
  end
  return category
end

function entity_utils.get_stored_size(entity)
  return tonumber(string.match(entity.order, ".-|(%d+)"))
end

function entity_utils.get_powered_entity(entity)
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

function entity_utils.launch_ticks(entity)
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

  return ticks
end

function entity_utils.process_producers(entity, producers)
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

return entity_utils