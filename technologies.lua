local state = require("state")

local technologies = {}

function prerequisites(technology)
  local result = {}

  for name, prereq in pairs(technology.prerequisites) do
    table.insert(result, "technology-" .. name)
  end

  return next(result) and result or nil
end

function technologies.technology(technology)
  local result = {prerequisites = prerequisites(technology)}

  for _, effect in ipairs(technology.effects) do
    if effect.type == "belt-stack-size-bonus" then
      result.beltStack = (result.beltStack or 0) + effect.modifier
    elseif effect.type == "bulk-inserter-stack-size-bonus" then
      if not result.inserterStack then
        result.inserterStack = {}
      end

      table.insert(result.inserterStack, {value = effect.modifier, category = "bulk"})
    elseif effect.type == "change-recipe-productivity" then
      if not result.recipeProductivity then
        result.recipeProductivity = {}
      end

      table.insert(result.recipeProductivity, {id = effect.recipe, value = effect.change})
    elseif effect.type == "inserter-stack-size-bonus" then
      if not result.inserterStack then
        result.inserterStack = {}
      end

      table.insert(result.inserterStack, {value = effect.modifier})
    elseif effect.type == "laboratory-productivity" then
      result.researchProductivity = (result.researchProductivity or 0) + effect.modifier
    elseif effect.type == "laboratory-speed" then
      result.researchSpeed = (result.researchSpeed or 0) + effect.modifier
    elseif effect.type == "mining-drill-productivity-bonus" then
      result.miningProductivity = (result.miningProductivity or 0) + effect.modifier
    elseif effect.type == "unlock-quality" then
      if not result.qualityUnlock then
        result.qualityUnlock = {}
      end

      table.insert(result.qualityUnlock, effect.quality)
    elseif effect.type == "unlock-recipe" then
      if not result.recipeUnlock then
        result.recipeUnlock = {}
      end

      table.insert(result.recipeUnlock, effect.recipe)
      state.recipes_locked[effect.recipe] = true
    end
  end

  return result
end

return technologies
