state = {}

-- The first player, used to request translations and take icons screenshot.
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
-- Optional flags to be added based on data. Record<string, true>
state.flags = {}
-- Icons to be generated during write_icons. { sprite: string, scale: number }[]
state.icons = {}
-- Qualities with level > 0 in this data. Used to generate quality info for entities.
state.abnormal_qualities = {}
-- Meta items. { item: Item, sprite: string, scale: number, proto: Entity }[]
state.items_meta = {}
-- Items used in recipes. Record<string, true>
state.items_used = {}
-- Items removed because they are not needed in the final data. Record<string, true>
state.items_removed = {}
-- Meta recipes. { recipe: Recipe, sprite: string, scale: number, localised_string: string, proto: Entity }[]
state.recipes_meta = {}
-- Recipes that can be enabled in this data set. Record<string, true>
state.recipes_enabled = {}
-- Recipes locked by technologies. Record<string, true>
state.recipes_locked = {}
-- Recipes that are specified as the fixed_recipe of a prototype. Record<string, true>
state.recipes_fixed = {}
-- Producer ids. Record<string, string[]>
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
-- Map of item id to item. Record<string, Item>
state.item_map = {}
-- Tick of last log message. number | nil
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
