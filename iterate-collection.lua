local state = require("state")

return function(collection, current_fn, next_fn)
  local entries_per_tick = state.entries_per_tick
  local next, _, key = pairs(collection)

  script.on_event(
    defines.events.on_tick,
    function()
      for i = 1, entries_per_tick do
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
