local process_collection = require("process-collection")
local filter_items = require("filter-items")
local state = require("state")
local translations = require("translations")

return function()
  log("init process_qualities")
  state.print("init process_qualities")

  if #prototypes.quality > 1 then
    state.data.qualities = {}

    local function process_quality(name, proto)
      if proto.parameter or proto.hidden then
        return
      end

      local sprite = "quality/" .. name
      local quality = {id = name, icon = sprite, level = proto.level}
      table.insert(state.data.qualities, quality)
      table.insert(state.icons, {sprite = sprite, scale = 1})
      translations.add(proto.localised_name, quality)
    end

    process_collection(prototypes.quality, process_quality, filter_items)
  else
    script.on_event(defines.events.on_tick, filter_items)
  end

  log("end process_qualities")
end
