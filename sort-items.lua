local sort_recipes = require("sort-recipes")
local state = require("state")
local utils = require("utils")

return function()
  table.sort(
    state.items_meta,
    function(a, b)
      return utils.compare_protos(a, b)
    end
  )

  script.on_event(defines.events.on_tick, sort_recipes)
end
