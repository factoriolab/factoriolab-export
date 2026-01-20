state = {}

state.player = nil
state.data = {
  version = script.active_mods,
  flags = {
    "fluidCostRatio",
    "maximumFactor",
    "minimumFactor",
    "miningDepletion",
    "miningProductivity",
    "mods",
    "pollution",
    "power",
    "researchSpeed"
  },
  categories = {},
  icons = {},
  items = {},
  recipes = {},
  locations = {}
}
state.icons = {}

return state
