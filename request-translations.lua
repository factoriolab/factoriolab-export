local state = require("state")
local translations = require("translations")
local write_icons = require("write-icons")

return function()
  log("init request_translations")
  state.print("init request_translations")

  translations.request(game.get_player(1), write_icons)

  log("end request_translations")
end
