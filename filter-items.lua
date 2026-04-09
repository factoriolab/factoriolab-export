local filter_recipes = require("filter-recipes")
local state = require("state")

return function()
  log("init filter_items")
  state.print("init filter_items")

  local result = {}
  for _, meta in pairs(state.items_meta) do
    if state.items_used[meta.item.id] then
      table.insert(result, meta)
    else
      state.items_removed[meta.item.id] = true
    end
  end

  state.items_meta = result

  script.on_event(defines.events.on_tick, filter_recipes)
  log("end filter_items")
end
