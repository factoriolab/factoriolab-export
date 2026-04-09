local finalize_items = require("finalize-items")

return function()
  log("init sort_recipes")
  state.print("init sort_recipes")

  script.on_event(defines.events.on_tick, finalize_items)
  log("end sort_recipes")
end
