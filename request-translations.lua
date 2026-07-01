local translations = require("translations")
local write_icons = require("write-icons")

return function()
  translations.request(game.get_player(1), write_icons)
  script.on_event(defines.events.on_tick, nil)
end
