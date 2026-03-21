local process_collection = require("process-collection")
local state = require("state")
local translations = require("translations")
local process_qualities = require("process-qualities")

return function()
  log("init process_locations")

  local function process_space_location(name, proto)
    if proto.parameter then
      return
    end

    if proto.type ~= "planet" then
      return
    end

    local sprite = "space-location/" .. name
    local location = {id = name, icon = sprite}
    table.insert(state.data.locations, location)
    table.insert(state.icons, {sprite = sprite, scale = 2})
    translations.add(proto.localised_name, location)
  end

  local function process_surface(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "surface/" .. name
    local location = {id = name, icon = sprite}
    table.insert(state.data.locations, location)
    table.insert(state.icons, {sprite = sprite, scale = 2})
    translations.add(proto.localised_name, location)
  end

  process_collection(
    prototypes.space_location,
    process_space_location,
    function()
      process_collection(prototypes.surface, process_surface, process_qualities)
    end
  )

  log("end process_locations")
end
