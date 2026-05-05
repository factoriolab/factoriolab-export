local sort_items = require("sort-items")
local state = require("state")

return function()
  local result = {}
  for _, meta in ipairs(state.recipes_meta) do
    local keep = true
    for id, _ in pairs(meta.recipe["in"]) do
      if state.items_removed[id] then
        keep = false
        break
      end
    end

    if keep then
      for id, _ in pairs(meta.recipe["out"]) do
        if state.items_removed[id] then
          keep = false
          break
        end
      end
    end

    if keep then
      table.insert(result, meta)
    end
  end

  state.recipes_meta = result

  script.on_event(defines.events.on_tick, sort_items)
end
