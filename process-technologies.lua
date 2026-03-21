local process_collection = require("process-collection")
local process_categories = require("process-categories")
local state = require("state")
local translations = require("translations")
local technologies = require("technologies")

return function()
  log("init process_technologies")

  local function process_technology(name, proto)
    if proto.parameter or proto.hidden or proto.enabled == false then
      return
    end

    local sprite = "technology/" .. name
    local item = {
      id = "technology-" .. name,
      icon = sprite,
      row = 0, -- TODO: Technology sorting
      category = "technology",
      technology = technologies.technology(proto)
    }
    table.insert(state.data.items, item)
    table.insert(state.icons, {sprite = sprite, scale = 0.5})
    translations.add(proto.localised_name, item)
  end

  process_collection(
    prototypes.technology,
    process_technology,
    function()
      script.on_event(defines.events.on_tick, process_categories)
    end
  )
  log("end process_technologies")
end
