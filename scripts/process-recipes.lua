local process_collection = require("process-collection")
local process_locations = require("process-locations")
local state = require("state")
local translate_collection = require("translate-collection")
local utils = require("utils")

return function()
  log("init process_recipes")
  local localised_strings = {}
  local recipe_row = utils.get_row_fn()

  local function process_recipe(name, proto)
    local sprite = "recipe/" .. name
    table.insert(
      state.data.recipes,
      {
        id = name,
        icon = sprite,
        row = recipe_row(proto),
        category = proto.group.name
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  local function finalize_recipes()
    translate_collection(state.player, localised_strings, state.data.recipes, process_locations)
    script.on_event(defines.events.on_tick, nil)
  end

  process_collection(prototypes.recipe, process_recipe, finalize_recipes)
  log("end process_recipes")
end
