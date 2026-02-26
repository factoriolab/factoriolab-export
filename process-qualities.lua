local process_collection = require("process-collection")
local state = require("state")
local translations = require("translations")
local process_translations = require("process-translations")
local write_icons = require("write-icons")

return function()
  log("init process_qualities")

  if #prototypes.quality > 1 then
    state.data.qualities = {}

    local function process_quality(name, proto)
      if proto.parameter then
        return
      end

      local sprite = "quality/" .. name
      local quality = {id = name, icon = sprite, level = proto.level}
      table.insert(state.data.qualities, quality)
      table.insert(state.icons, {sprite = sprite, scale = 1})
      translations.add(proto.localised_name, quality)
    end

    process_collection(prototypes.quality, process_quality, process_translations)
  else
    script.on_event(defines.events.on_tick, write_icons)
  end

  log("end process_qualities")
end
