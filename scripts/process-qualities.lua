local process_collection = require("process-collection")
local state = require("state")
local translate_collection = require("translate-collection")
local write_icons = require("write-icons")

return function()
  log("init process_qualities")

  if #prototypes.quality > 1 then
    state.data.qualities = {}

    local localised_strings = {}
    local localised_lookup = {}

    local function process_quality(name, proto)
      local sprite = "quality/" .. name
      local quality = {id = name, icon = sprite, level = proto.level}
      table.insert(state.data.qualities, quality)
      table.insert(state.icons, {sprite = sprite, scale = 1})
      table.insert(localised_strings, proto.localised_name)
      table.insert(localised_lookup, {quality})
    end

    local function finalize_qualities()
      log("init finalize_qualities")
      translate_collection(state.player, localised_strings, localised_lookup, write_icons)
      script.on_event(defines.events.on_tick, nil)
      log("end finalize_qualities")
    end

    process_collection(prototypes.quality, process_quality, finalize_qualities)
  else
    script.on_event(defines.events.on_tick, write_icons)
  end

  log("end process_qualities")
end
