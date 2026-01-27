local process_collection = require("process-collection")
local state = require("state")
local translate_collection = require("translate-collection")
local process_qualities = require("process-qualities")

return function()
  log("init process_locations")
  local localised_strings = {}

  local function process_space_location(name, proto)
    if proto.type ~= "planet" then
      return
    end

    local sprite = "space-location/" .. name
    table.insert(state.data.locations, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function process_surface(name, proto)
    local sprite = "surface/" .. name
    table.insert(state.data.locations, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function finalize_surfaces()
    translate_collection(state.player, localised_strings, state.data.locations, process_qualities)
    script.on_event(defines.events.on_tick, nil)
  end

  local function finalize_space_locations()
    process_collection(prototypes.surface, process_surface, finalize_surfaces)
  end

  process_collection(prototypes.space_location, process_space_location, finalize_space_locations)

  log("end process_locations")
end
