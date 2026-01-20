local process_categories = require("scripts/process-categories")
local state = require("scripts/state")

local function setup()
  log("init setup")
  state.player = game.players[1]
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

  script.on_event(defines.events.on_tick, process_categories)
  log("end setup")
end

script.on_event(defines.events.on_tick, setup)
