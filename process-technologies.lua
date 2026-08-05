local iterate_collection = require("iterate-collection")
local process_items = require("process-items")
local state = require("state")
local technologies = require("technologies")

return function()
  local function process_technology(name, proto)
    if proto.parameter or proto.hidden or proto.enabled == false then
      return
    end

    local sprite = "technology/" .. name
    local id = "technology-" .. name
    local item = {
      id = id,
      icon = sprite,
      row = #proto.research_unit_ingredients,
      category = "technology",
      technology = technologies.technology(proto)
    }
    state.items_used[item.id] = true
    table.insert(state.items_meta, {item = item, sprite = sprite, scale = 0.5, proto = proto})

    local technology = state.player.force.technologies[name]
    if technology.researched or technology.level > 1 then
      table.insert(state.data.defaults.researchedTechnologies, id)
    end

    if #proto.research_unit_ingredients > 0 then
      local ingredients = {}
      for _, ingredient in ipairs(proto.research_unit_ingredients) do
        local id = "item-" .. ingredient.name
        if not ingredients[id] then
          ingredients[id] = 0
        end

        ingredients[id] = ingredients[id] + ingredient.amount
      end

      local recipe = {
        id = id,
        icon = sprite,
        row = #proto.research_unit_ingredients,
        category = "technology",
        time = proto.research_unit_energy / 60,
        producers = state.machines.lab,
        ["in"] = ingredients,
        out = {[id] = 1},
        flags = {"technology"}
      }
      table.insert(state.recipes_meta, {recipe = recipe, proto = proto})
    end
  end

  state.data.defaults.miningBonus = state.player.force.mining_drill_productivity_bonus * 100
  state.data.defaults.researchBonus = state.player.force.laboratory_speed_modifier * 100
  state.data.defaults.researchProductivity = state.player.force.laboratory_productivity_bonus * 100

  iterate_collection(
    prototypes.technology,
    process_technology,
    function()
      script.on_event(defines.events.on_tick, process_items)
    end
  )
end
