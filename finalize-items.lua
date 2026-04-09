local finalize_recipes = require("finalize-recipes")
local state = require("state")
local translations = require("translations")

return function()
  log("init finalize_items")
  state.print("init finalize_items")

  for _, meta in pairs(state.items_meta) do
    table.insert(state.data.items, meta.item)
    table.insert(state.icons, {sprite = meta.sprite, scale = meta.scale})
    translations.add(meta.proto.localised_name, meta.item)
  end

  script.on_event(defines.events.on_tick, finalize_recipes)
  log("end finalize_items")
end
