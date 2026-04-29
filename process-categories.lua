local process_locations = require("process-locations")
local iterate_collection = require("iterate-collection")
local state = require("state")
local translations = require("translations")

return function()
  local function process_category(name, proto)
    local sprite = "item-group/" .. name
    local category = {id = name, icon = sprite}
    table.insert(state.data.categories, category)
    table.insert(state.icons, {sprite = sprite, scale = 1})
    translations.add(proto.localised_name, category)
  end

  iterate_collection(
    prototypes.item_group,
    process_category,
    function()
      local category = {id = "technology", icon = "item/lab"}
      table.insert(state.data.categories, category)
      translations.add({"gui-map-generator.technology-difficulty-group-tile"}, category)
      script.on_event(defines.events.on_tick, process_locations)
    end
  )
end
