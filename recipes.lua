local state = require("state")

local recipes = {}

function recipes.ingredients(recipe)
  local result = {}

  for _, ingredient in ipairs(recipe.ingredients) do
    local id = ingredient.type .. "-" .. ingredient.name
    result[id] = ingredient.amount
  end

  return result
end

function recipes.included(recipe)
  if
    not state.recipes_fixed[recipe.name] and recipe.enabled == false and
      (not state.recipes_locked[recipe.name] or recipe.hidden)
   then
    return false
  end

  if #recipe.ingredients == 0 and #recipe.products == 0 then
    return false
  end

  return true
end

function recipes.products(products)
  local result = {}
  local catalyst
  local total = 0

  for _, product in ipairs(products) do
    local id = product.type .. "-" .. product.name
    local amount = product.amount
    if not amount then
      amount = (product.amount_max + product.amount_min) / 2
    end

    if product.probability then
      amount = amount * product.probability
    end

    if product.extra_count_fraction then
      amount = product.extra_count_fraction
    end

    if not result[id] then
      result[id] = 0
    end

    result[id] = result[id] + amount
    total = total + amount

    if product.ignored_by_productivity then
      if not catalyst then
        catalyst = {}
      end

      if not catalyst[id] then
        catalyst[id] = 0
      end

      catalyst[id] = catalyst[id] + product.ignored_by_productivity
    end
  end

  return result, catalyst, total
end

function recipes.save(recipe, localised_name, sprite, scale)
  if not proto or proto.category ~= "recycling" then
    for id, _ in pairs(recipe["in"]) do
      state.items_used[id] = true
    end

    for id, _ in pairs(recipe["out"]) do
      state.items_used[id] = true
    end
  end

  table.insert(
    state.recipes_meta,
    {recipe = recipe, localised_name = localised_name, sprite = sprite, scale = scale, proto = proto}
  )
end

function recipes.store_used_items(recipe)
  for id, _ in pairs(recipe["in"]) do
    state.items_used[id] = true
  end

  for id, _ in pairs(recipe["out"]) do
    state.items_used[id] = true
  end
end

function recipes.add_value(entity, key, value)
  if not entity[key] then
    entity[key] = value
  else
    entity[key] = entity[key] + value
  end
end

function recipes.as_percentage(entity)
  local total = 0
  for _, value in pairs(entity) do
    total = total + value
  end

  local result = {}
  for key, value in pairs(entity) do
    result[key] = value / total
  end

  return result
end

return recipes
