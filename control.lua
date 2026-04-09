local process_technologies = require("process-technologies")
local state = require("state")

local function setup()
  log("init setup")
  state.player = game.get_player(1)
  if state.player == nil then
    log("no player found")
    return
  end

  if script.feature_flags.quality then
    table.insert(state.data.flags, "quality")
  end

  if script.feature_flags.space_travel then
    table.insert(state.data.flags, "rockets")
  end

  script.on_event(defines.events.on_tick, process_technologies)
  log("end setup")
end

script.on_event(defines.events.on_tick, setup)
