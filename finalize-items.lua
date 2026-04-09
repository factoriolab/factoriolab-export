local finalize_recipes = require("finalize-recipes")
local get_row_fn = require("get-row-fn")
local state = require("state")
local translations = require("translations")

return function()
  log("init finalize_items")
  state.print("init finalize_items")

  local item_row = get_row_fn()
  for _, meta in ipairs(state.items_meta) do
    local item = meta.item
    if not item.row then
      item.row = item_row(meta.proto)
    end
    if not item.category then
      item.category = meta.proto.group.name
    end
    table.insert(state.data.items, meta.item)
    table.insert(state.icons, {sprite = meta.sprite, scale = meta.scale})
    translations.add(meta.proto.localised_name, meta.item)
  end

  script.on_event(defines.events.on_tick, finalize_recipes)
  log("end finalize_items")
end
