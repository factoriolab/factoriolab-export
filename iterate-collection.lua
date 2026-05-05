return function(collection, current_fn, next_fn, protos_per_tick)
  protos_per_tick = protos_per_tick or 200
  local next, _, key = pairs(collection)

  script.on_event(
    defines.events.on_tick,
    function()
      for i = 1, protos_per_tick do
        local name, proto = next(collection, key)
        key = name
        if proto then
          current_fn(name, proto)
        else
          script.on_event(defines.events.on_tick, next_fn)
          break
        end
      end
    end
  )
end
