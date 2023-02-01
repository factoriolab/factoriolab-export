local dictionary = require("__flib__.dictionary")
local event = require("__flib__.event")

local export_data = require("scripts/export-data")

local function create_dictionaries()
  for _, type in pairs({"fluid", "item", "item_group", "recipe", "technology"}) do
    -- If the object's name doesn't have a translation, use its internal name as the translation
    local Names = dictionary.new(type .. "_names", true)
    for name, prototype in pairs(game[type .. "_prototypes"]) do
      Names:add(name, prototype.localised_name)
    end
  end
  local GuiNames = dictionary.new("gui_technology_names", true)
  GuiNames:add("research", {"gui-technology-progress.title"})
end

event.on_init(
  function()
    dictionary.init()
    create_dictionaries()
  end
)

event.on_player_created(
  function(e)
    local player = game.players[e.player_index]
    local player_settings = settings.get_player_settings(player)
    if player_settings["factoriolab-export-disable"].value then
      log("skipping data export")
      return
    end
    player.print({"factoriolab-export.initialize"})
    dictionary.translate(player)
  end
)

event.on_string_translated(
  function(e)
    local language_data = dictionary.process_translation(e)
    if language_data then
      for _, player_index in pairs(language_data.players) do
        export_data(player_index, language_data)
      end
    end
  end
)
