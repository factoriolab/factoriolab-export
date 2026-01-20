local state = require("scripts/state")

return function()
  log("init write_data")
  helpers.write_file("data.json", helpers.table_to_json(state.data))
  script.on_event(defines.events.on_tick, nil)
  log("end write_data")
end
