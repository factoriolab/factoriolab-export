local iterate_collection = require("iterate-collection")
local filter_items = require("filter-items")
local state = require("state")
local translations = require("translations")

return function()
  local has_abnormal_quality = false
  for name, proto in pairs(prototypes.quality) do
    if not proto.parameter and not proto.hidden and proto.level > 0 then
      has_abnormal_quality = true
      break
    end
  end

  if has_abnormal_quality then
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

    iterate_collection(prototypes.quality, process_quality, filter_items)
  else
    script.on_event(defines.events.on_tick, filter_items)
  end
end
