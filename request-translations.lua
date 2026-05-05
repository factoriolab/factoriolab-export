local translations = require("translations")
local write_icons = require("write-icons")

return function()
  translations.request(game.get_player(1), write_icons)
end
