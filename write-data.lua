local state = require("state")

return function()
  -- Add extra flags
  for flag, value in pairs(state.flags) do
    if value then
      table.insert(state.data.flags, flag)
    end
  end

  helpers.write_file("data.json", helpers.table_to_json(state.data))
  script.on_event(defines.events.on_tick, nil)
  state.player.print({"factoriolab-export.complete"})
end
