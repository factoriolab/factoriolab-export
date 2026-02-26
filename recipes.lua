local recipes = {}

function recipes.ingredients(recipe)
  local result = {}

  for _, ingredient in ipairs(recipe.ingredients) do
    local id = ingredient.type .. "-" .. ingredient.name
    result[id] = ingredient.amount
  end

  return result
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

return recipes
