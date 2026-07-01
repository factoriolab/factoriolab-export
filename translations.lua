local translations = {}

local localised_strings = {}
local items = {}
local requests = {}

function translations.add(localised_string, item)
  table.insert(localised_strings, localised_string)
  table.insert(items, item)
end

function translations.request(player, nextFn)
  local ids = player.request_translations(localised_strings)
  for i = 1, #ids do
    requests[ids[i]] = i
  end

  script.on_event(
    defines.events.on_string_translated,
    function(e)
      local i = requests[e.id]
      if i == nil then
        return
      end
      requests[e.id] = nil
      items[i].name = e.result

      if next(requests) == nil then
        localised_strings = {}
        items = {}
        requests = {}
        script.on_event(defines.events.on_string_translated, nil)
        script.on_event(defines.events.on_tick, nextFn)
      end
    end
  )
end

return translations
