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
  local fixed_recipe = {}
  for _, entity in pairs(game.entity_prototypes) do
    if entity.fixed_recipe then
      fixed_recipe[entity.fixed_recipe] = true
    end
  end

  for name, recipe in pairs(game.recipe_prototypes) do
    local include = true

    -- Skip recipes that don't have outputs
    if not recipe.products or not (#recipe.products > 0) then
      include = false
    else
      local out, catalyst, total = utils.calculate_products(recipe.products)
      if total == 0 then
        include = false
      end
    end

    -- Always include fixed recipes (that do have outputs)
    if not fixed_recipe[name] then
      -- Skip recipes that are not unlocked / enabled
      if recipe.enabled == false and not recipes_unlocked[name] then
        include = false
      end

      -- Skip recipes that are hidden
      if recipe.hidden == true then
        include = false
      end
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

local function sort_protos(items_used, recipes_enabled)
  local proto_list = {}
  for name, _ in pairs(items_used) do
    local item = game.item_prototypes[name]
    if item then
      table.insert(
        proto_list,
        {
          item = item,
          fluid = nil,
          recipe = nil,
          name = item.name,
          order = item.order,
          sgname = item.subgroup.name,
          sgorder = item.subgroup.order,
          gname = item.group.name,
          gorder = item.group.order
        }
      )
    end

    local fluid = game.fluid_prototypes[name]
    if fluid then
      table.insert(
        proto_list,
        {
          item = nil,
          fluid = fluid,
          recipe = nil,
          name = fluid.name,
          order = fluid.order,
          sgname = fluid.subgroup.name,
          sgorder = fluid.subgroup.order,
          gname = fluid.group.name,
          gorder = fluid.group.order
        }
      )
    end
  end

  for name, recipe in pairs(recipes_enabled) do
    table.insert(
      proto_list,
      {
        item = nil,
        fluid = nil,
        recipe = recipe,
        name = recipe.name,
        order = recipe.order,
        sgname = recipe.subgroup.name,
        sgorder = recipe.subgroup.order,
        gname = recipe.group.name,
        gorder = recipe.group.order
      }
    )
  end

  utils.sort_by(proto_list, "gorder", "gname", "sgorder", "sgname", "order", "name")

  local sorted_protos = {}
  for i = 1, #proto_list do
    local proto = proto_list[i]
    table.insert(
      sorted_protos,
      {
        item = proto.item,
        fluid = proto.fluid,
        recipe = proto.recipe
      }
    )
  end

  return sorted_protos
end

return function()
  local recipes_unlocked = process_technology()
  local recipes_enabled = process_recipes(recipes_unlocked)
  local items_used = process_items(recipes_enabled)
  return sort_protos(items_used, recipes_enabled)
end
