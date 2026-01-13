local requests = {}

return function(player, localised_strings, collection, nextFn)
  local ids = player.request_translations(localised_strings)
  for i = 1, #ids do
    requests[ids[i]] = i
  end

  script.on_event(
    defines.events.on_string_translated,
    function(e)
      local i = requests[e.id]
      requests[e.id] = nil
      collection[i].name = e.result

      if #requests == 0 then
        script.on_event(defines.events.on_tick, nextFn)
      end
    end
  )
end
