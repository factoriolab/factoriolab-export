local process_technologies = require("process-technologies")
local state = require("state")

local function setup(player)
  state.player = player
  state.player.print({"factoriolab-export.initiate"})

  state.entries_per_tick = settings.global["factoriolab-export-entries-per-tick"].value
  if script.feature_flags.space_travel then
    table.insert(state.data.flags, "rockets")
  end

  script.on_event(defines.events.on_tick, process_technologies)
end

-- Quickbar shortcut
script.on_event(
  defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name == "factoriolab-export-run" then
      local player = game.get_player(event.player_index)
      setup(player)
    end
  end
)

-- Keyboard shortcuts
script.on_event(
  "factoriolab-export-run",
  function(event)
    local player = game.get_player(event.player_index)
    setup(player)
  end
)
