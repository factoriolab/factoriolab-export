local get_row = require("scripts/get-row")
local translate_collection = require("scripts/translate-collection")

local player
local data = {
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
  recipes = {}
}
local requests = {}
local icons = {}

script.on_event(
  defines.events.on_string_translated,
  function(e)
    log("translated")
  end
)

-- Step 6
local function write_data()
  log("init write_data")
  helpers.write_file("data.json", helpers.table_to_json(data))
  script.on_event(defines.events.on_tick, nil)
  log("end write_data")
end

-- Step 5
local function write_icons()
  log("init write_icons")
  local sprite_surface = game.create_surface("lab-sprite")

  -- Calculate sprite sheet width (height determined by # of loop iterations)
  local width = math.max(math.ceil((#icons) ^ 0.5), 8)
  local x_position = width - 1
  local x_resolution = width * 64

  local x = 0
  local y = 0
  for _, icon in pairs(icons) do
    rendering.draw_sprite(
      {
        sprite = icon.sprite,
        x_scale = icon.scale,
        y_scale = icon.scale,
        target = {x = x * 2, y = y * 2},
        surface = sprite_surface
      }
    )

    table.insert(
      data.icons,
      {
        id = icon.sprite,
        x = x,
        y = y
      }
    )

    x = x + 1
    if x == width then
      y = y + 1
      x = 0
    end
  end

  if x == 0 then
    y = y - 1
  end

  local rows = y + 1
  local y_resolution = rows * 64
  local y_position = rows - 1

  game.take_screenshot(
    {
      player = player,
      by_player = player,
      surface = sprite_surface,
      position = {x_position, y_position},
      resolution = {x_resolution, y_resolution},
      zoom = 1,
      quality = 100,
      daytime = 1,
      path = "icons.png",
      show_gui = false,
      show_entity_info = false,
      anti_alias = false
    }
  )

  script.on_event(defines.events.on_tick, write_data)
  log("end write_icons")
end

-- Step 4
local function process_recipes()
  log("init process_recipes")
  local localised_strings = {}
  local recipe_row = get_row()
  for name, recipe in pairs(prototypes.recipe) do
    local sprite = "recipe/" .. name
    table.insert(data.recipes, {id = name, icon = sprite, row = recipe_row(recipe)})
    table.insert(icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, recipe.localised_name)
  end

  translate_collection(player, localised_strings, data.recipes, write_icons)
  script.on_event(defines.events.on_tick, nil)
  log("end process_recipes")
end

-- Step 3
local function process_items()
  log("init process_items")
  local localised_strings = {}
  local item_row = get_row()
  for name, item in pairs(prototypes.item) do
    local sprite = "item/" .. name
    table.insert(data.items, {id = name, icon = sprite, row = item_row(item)})
    table.insert(icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, item.localised_name)
  end

  for name, fluid in pairs(prototypes.fluid) do
    local sprite = "fluid/" .. name
    table.insert(data.items, {id = name, icon = sprite, row = item_row(fluid)})
    table.insert(icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, fluid.localised_name)
  end

  for name, technology in pairs(prototypes.technology) do
    local sprite = "technology/" .. name
    table.insert(data.items, {id = name, icon = sprite, row = item_row(technology)})
    table.insert(icons, {sprite = sprite, scale = 0.5})
    table.insert(localised_strings, technology.localised_name)
  end

  translate_collection(player, localised_strings, data.items, process_recipes)
  script.on_event(defines.events.on_tick, nil)
  log("end process_items")
end

-- Step 2
local function process_categories()
  log("init process_categories")
  local localised_strings = {}
  for name, itemGroup in pairs(prototypes.item_group) do
    local sprite = "item-group/" .. name
    table.insert(data.categories, {id = name, icon = sprite})
    table.insert(icons, {sprite = sprite, scale = 1})
    table.insert(localised_strings, itemGroup.localised_name)
  end

  translate_collection(player, localised_strings, data.categories, process_items)
  script.on_event(defines.events.on_tick, nil)
  log("end process_categories")
end

-- Step 1
local function setup()
  log("init setup")
  player = game.players[1]
  if player == nil then
    log("no player found")
    return
  end

  if script.feature_flags.quality then
    table.insert(data.flags, "quality")
  end

  if script.feature_flags.space_travel then
    table.insert(data.flags, "rockets")
  end

  script.on_event(defines.events.on_tick, process_categories)
  log("end setup")
end

script.on_event(defines.events.on_tick, setup)
