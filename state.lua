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
state.flags = {}
state.icons = {}
state.abnormal_qualities = {}
state.recipes_locked = {}
state.producers = {
  burner = {},
  crafting = {},
  resource = {},
  resource_fluid = {},
  asteroid = {}
}
state.machines = {
  boiler = {},
  offshore_pump = {},
  silo = {}
}
state.item_map = {}

for name, quality in pairs(prototypes.quality) do
  if quality.level > 0 then
    state.abnormal_qualities[name] = quality
  end
end

return state
