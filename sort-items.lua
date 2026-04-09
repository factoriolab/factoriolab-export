local sort_recipes = require("sort-recipes")

return function()
  log("init sort_items")
  state.print("init sort_items")

  script.on_event(defines.events.on_tick, sort_recipes)
  log("end sort_items")
end
