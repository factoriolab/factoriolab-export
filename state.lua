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
state.items_meta = {}
state.items_used = {}
state.recipes_meta = {}
state.recipes_enabled = {}
state.recipes_locked = {}
state.recipes_fixed = {}
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
state.tick = nil

for name, quality in pairs(prototypes.quality) do
  if quality.level > 0 then
    state.abnormal_qualities[name] = quality
  end
end

function state.print(message)
  if not state.tick then
    state.tick = game.tick
  end

  local ticks = game.tick - state.tick
  state.tick = game.tick
  state.player.print(message .. " " .. ticks)
end

return state
