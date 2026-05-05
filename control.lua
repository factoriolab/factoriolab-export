local process_technologies = require("process-technologies")
local state = require("state")

local function setup()
  if not settings.global["factoriolab-export-enabled"].value then
    return
  end

  state.player = game.get_player(1)
  if state.player == nil then
    log({"factoriolab-export.no-player-found"})
    return
  end

  state.player.print({"factoriolab-export.initiate"})
  if script.feature_flags.space_travel then
    table.insert(state.data.flags, "rockets")
  end

  script.on_event(defines.events.on_tick, process_technologies)
end

script.on_event(defines.events.on_tick, setup)
