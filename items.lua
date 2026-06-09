local state = require("state")

local items = {}

function items.fuel(item)
  return {
    category = item.fuel_category,
    value = item.fuel_value / 1000000,
    result = item.burnt_result and "item-" .. item.burnt_result.name or nil,
    pollutionMultiplier = item.fuel_emissions_multiplier ~= 1 and item.fuel_emissions_multiplier or nil
  }
end

function items.module(item)
  local module = item.get_module_effects()

  if module.quality then
    module.quality = module.quality / 10
  end

  local quality_record = {}
  for name, quality in pairs(state.abnormal_qualities) do
    local variant = {}

    local effects = item.get_module_effects(name)
    for effName, effValue in pairs(effects) do
      if effName == "quality" then
        effValue = effValue / 10
      end

      if module[effName] ~= effValue then
        variant[effName] = effValue
      end
    end

    if next(variant) ~= nil then
      quality_record[name] = variant
    end
  end

  if next(quality_record) ~= nil then
    module.qualityRecord = quality_record
  end

  return module
end

return items
