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
state.abnormal_qualities = {}

for name, quality in pairs(prototypes.quality) do
  if quality.level > 0 then
    state.abnormal_qualities[name] = quality
  end
end

return state
