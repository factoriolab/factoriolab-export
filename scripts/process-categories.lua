local process_collection = require("process-collection")
local process_items = require("process-items")
local state = require("state")
local translate_collection = require("translate-collection")

return function()
  log("init process_categories")
  local localised_strings = {}

  local function process_category(name, proto)
    local sprite = "item-group/" .. name
    table.insert(state.data.categories, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 1})
    table.insert(localised_strings, proto.localised_name)
  end

  local function finalize_categories()
    log("init finalize_categories")

    table.insert(state.data.categories, {id = "technology", icon = "item/lab"})
    table.insert(localised_strings, {"gui-map-generator.technology-difficulty-group-tile"})

    translate_collection(state.player, localised_strings, state.data.categories, process_items)
    script.on_event(defines.events.on_tick, nil)
    log("end finalize_categories")
  end

  process_collection(prototypes.item_group, process_category, finalize_categories)
  log("end process_categories")
end
