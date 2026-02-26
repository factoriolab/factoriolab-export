local write_icons = require("write-icons")
local translations = require("translations")
local state = require("state")

return function()
  log("init process_translations")
  translations.request(state.player, write_icons)
  log("end process_translations")
end
