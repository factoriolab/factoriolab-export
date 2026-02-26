local process_collection = require("process-collection")
local process_categories = require("process-categories")

return function()
  log("init process_technologies")

  local function process_technology(name, proto)
    if proto.parameter then
      return
    end

    local sprite = "technology/" .. name
    log(name)
  end

  local function finalize_technologies()
    log("init finalize_technologies")
    script.on_event(defines.events.on_tick, process_categories)
    log("end finalize_technologies")
  end

  process_collection(prototypes.technology, process_technology, finalize_technologies)
  log("end process_technologies")
end
