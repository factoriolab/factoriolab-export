local get_row_fn = require("get-row-fn")
local request_translations = require("request-translations")
local state = require("state")
local translations = require("translations")

return function()
  log("init finalize_recipes")
  state.print("init finalize_recipes")

  local recipe_row = get_row_fn()
  for _, meta in pairs(state.recipes_meta) do
    local recipe = meta.recipe
    if not recipe.row then
      recipe.row = recipe_row(meta.proto)
    end
    if not recipe.category then
      recipe.category = meta.proto.group.name
    end
    table.insert(state.data.recipes, meta.recipe)

    if meta.sprite and meta.scale then
      table.insert(state.icons, {sprite = meta.sprite, scale = meta.scale})
    end

    if meta.localised_name then
      translations.add(meta.localised_name, meta.recipe)
    elseif meta.proto then
      translations.add(meta.proto.localised_name, meta.recipe)
    end
  end

  script.on_event(defines.events.on_tick, request_translations)
  log("end finalize_recipes")
end
