local finalize_items = require("finalize-items")
local state = require("state")
local utils = require("utils")

return function()
  table.sort(
    state.recipes_meta,
    function(a, b)
      return utils.compare_protos(a, b)
    end
  )

  script.on_event(defines.events.on_tick, finalize_items)
end
