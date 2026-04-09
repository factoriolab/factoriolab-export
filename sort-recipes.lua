local finalize_items = require("finalize-items")
local state = require("state")
local utils = require("utils")

return function()
  log("init sort_recipes")
  state.print("init sort_recipes")

  table.sort(
    state.recipes_meta,
    function(a, b)
      return utils.compare_protos(a, b)
    end
  )

  script.on_event(defines.events.on_tick, finalize_items)
  log("end sort_recipes")
end
