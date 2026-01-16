local entity_utils = require("scripts/entity-utils")
local translate_collection = require("scripts/translate-collection")
local utils = require("scripts/utils")

local state = {
  player = nil,
  data = {
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
  },
  icons = {}
}

-- Step 7
local function write_data()
  log("init write_data")
  helpers.write_file("data.json", helpers.table_to_json(state.data))
  script.on_event(defines.events.on_tick, nil)
  log("end write_data")
end

-- Step 6
local function write_icons()
  log("init write_icons")
  local sprite_surface = game.create_surface("lab-sprite")

  -- Calculate sprite sheet width (height determined by # of loop iterations)
  local width = math.max(math.ceil((#state.icons) ^ 0.5), 8)
  local x_position = width - 1
  local x_resolution = width * 64

  local x = 0
  local y = 0
  for _, icon in pairs(state.icons) do
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
      state.data.icons,
      {
        id = icon.sprite,
        x = x * 64,
        y = y * 64
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
      player = state.player,
      by_player = state.player,
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

-- Step 5
local function process_locations()
  log("init process_locations")
  local localised_strings = {}
  for name, proto in pairs(prototypes.space_location) do
    local sprite = "space-location/" .. name
    table.insert(state.data.locations, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  for name, proto in pairs(prototypes.surface) do
    local sprite = "surface/" .. name
    table.insert(state.data.locations, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  translate_collection(state.player, localised_strings, state.data.locations, write_icons)
  script.on_event(defines.events.on_tick, nil)
  log("end process_locations")
end

-- Step 4
local function process_recipes()
  log("init process_recipes")
  local localised_strings = {}
  local recipe_row = utils.get_row_fn()
  for name, proto in pairs(prototypes.recipe) do
    local sprite = "recipe/" .. name
    table.insert(
      state.data.recipes,
      {
        id = name,
        icon = sprite,
        row = recipe_row(proto),
        category = proto.group.name
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  translate_collection(state.player, localised_strings, state.data.recipes, process_locations)
  script.on_event(defines.events.on_tick, nil)
  log("end process_recipes")
end

-- Step 3
local function process_items()
  log("init process_items")
  local localised_strings = {}
  local item_row = utils.get_row_fn()
  local item_map = {}

  for name, proto in pairs(prototypes.item) do
    local sprite = "item/" .. name
    local item = {
      id = name,
      icon = sprite,
      row = item_row(proto),
      category = proto.group.name,
      stack = proto.stack_size,
      rocketCapacity = proto.weight and proto.weight > 0 and
        math.floor(prototypes.utility_constants.rocket_lift_weight / proto.weight) or
        nil
    }

    -- TODO: Check for fuel?

    table.insert(state.data.items, item)
    item_map[name] = item
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  -- TODO: Include qualities?
  -- TODO: Crawl resources

  for name, proto in pairs(prototypes.entity) do
    if proto.type == "beacon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.beacon = entity_utils.beacon(proto)
    elseif proto.type == "transport-belt" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.belt = {speed = proto.belt_speed * 8 * 60}
    elseif proto.type == "pump" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.pipe = {speed = proto.get_pumping_speed() * 60}
    elseif proto.type == "agricultural-tower" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "assembling-machine" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "asteroid-collector" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "boiler" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "burner-generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "furnace" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "fusion-generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "fusion-reactor" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "generator" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "lab" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "mining-drill" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "offshore-pump" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "reactor" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "rocket-silo" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.machine = {} --TODO
    elseif proto.type == "module" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.module = {} --TODO
    elseif proto.type == "cargo-wagon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.cargoWagon = {} --TODO
    elseif proto.type == "fluid-wagon" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.fluidWagon = {} --TODO
    elseif proto.type == "inserter" then
      local item = item_map[name] or entity_utils.item(state, localised_strings, proto)
      item.inserter = {} --TODO
    end
  end

  for name, proto in pairs(prototypes.fluid) do
    local sprite = "fluid/" .. name
    table.insert(
      state.data.items,
      {
        id = name,
        icon = sprite,
        row = item_row(proto),
        category = proto.group.name
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 2})
    table.insert(localised_strings, proto.localised_name)
  end

  for name, proto in pairs(prototypes.technology) do
    local sprite = "technology/" .. name
    -- TODO: Include technology info
    table.insert(
      state.data.items,
      {
        id = name,
        icon = sprite,
        row = item_row(proto),
        category = "technology"
      }
    )
    table.insert(state.icons, {sprite = sprite, scale = 0.5})
    table.insert(localised_strings, proto.localised_name)
  end

  log(helpers.table_to_json(localised_strings))

  translate_collection(state.player, localised_strings, state.data.items, process_recipes)
  script.on_event(defines.events.on_tick, nil)
  log("end process_items")
end

-- Step 2
local function process_categories()
  log("init process_categories")
  local localised_strings = {}
  for name, proto in pairs(prototypes.item_group) do
    local sprite = "item-group/" .. name
    table.insert(state.data.categories, {id = name, icon = sprite})
    table.insert(state.icons, {sprite = sprite, scale = 1})
    table.insert(localised_strings, proto.localised_name)
  end

  table.insert(state.data.categories, {id = "technology", icon = "item/lab"})
  table.insert(localised_strings, {"gui-map-generator.technology-difficulty-group-tile"})

  translate_collection(state.player, localised_strings, state.data.categories, process_items)
  script.on_event(defines.events.on_tick, nil)
  log("end process_categories")
end

-- Step 1
local function setup()
  log("init setup")
  state.player = game.players[1]
  if state.player == nil then
    log("no player found")
    return
  end

  if script.feature_flags.quality then
    table.insert(state.data.flags, "quality")
  end

  if script.feature_flags.space_travel then
    table.insert(state.data.flags, "rockets")
  end

  script.on_event(defines.events.on_tick, process_categories)
  log("end setup")
end

script.on_event(defines.events.on_tick, setup)
