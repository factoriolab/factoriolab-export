local process_collection = require("process-collection")
local process_items = require("process-items")
local state = require("state")
local technologies = require("technologies")
local translations = require("translations")

return function()
  log("init process_technologies")
  state.print("init process_technologies")

  local function process_technology(name, proto)
    if proto.parameter or proto.hidden or proto.enabled == false then
      return
    end

    -- TODO: Improve technology ordering, technology recipes

    local sprite = "technology/" .. name
    local item = {
      id = "technology-" .. name,
      icon = sprite,
      row = #proto.research_unit_ingredients,
      category = "technology",
      technology = technologies.technology(proto)
    }
    state.items_used[item.id] = true
    table.insert(state.items_meta, {item = item, sprite = sprite, scale = 0.5, proto = proto})
  end

  process_collection(
    prototypes.technology,
    process_technology,
    function()
      script.on_event(defines.events.on_tick, process_items)
    end
  )
  log("end process_technologies")
end
