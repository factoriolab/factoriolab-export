local request_translations = require("request-translations")
local state = require("state")
local translations = require("translations")

return function()
  log("init filter_items")
  state.print("init filter_items")

  local removed = {}
  for i, meta in pairs(state.items_meta) do
    if state.items_used[meta.item.id] then
      table.insert(state.data.items, meta.item)
      table.insert(state.icons, {sprite = meta.sprite, scale = meta.scale})
      translations.add(meta.proto.localised_name, meta.item)
    else
      removed[meta.item.id] = true
    end
  end

  for i, meta in pairs(state.recipes_meta) do
    local remove = false
    for id, _ in pairs(meta.recipe["in"]) do
      if removed[id] then
        remove = true
        break
      end
    end

    if not remove then
      for id, _ in pairs(meta.recipe["out"]) do
        if removed[id] then
          remove = true
          break
        end
      end
    end

    if not remove then
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
  end

  script.on_event(defines.events.on_tick, request_translations)
  log("end filter_items")
end
