local utils = require("utils")

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

return function()
  local recipes_unlocked = process_technology()
  local recipes_enabled = process_recipes(recipes_unlocked)
  local items_used = process_items(recipes_enabled)
  local sorted_item_names = sort_items(items_used)

  return sorted_item_names, recipes_enabled
end
