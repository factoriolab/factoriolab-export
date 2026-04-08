local state = require("state")
local write_data = require("write-data")

return function()
  log("init write_icons")
  state.print("init write_icons")

  local sprite_surface = game.create_surface("lab-sprite")

  -- Calculate sprite sheet width (height determined by # of loop iterations)
  local width = math.max(math.ceil((#state.icons) ^ 0.5), 8)
  local x_position = width - 1 + (width / 64)
  local x_resolution = (width * 64) + width

  local x = 0
  local y = 0
  for _, icon in pairs(state.icons) do
    rendering.draw_sprite(
      {
        sprite = icon.sprite,
        x_scale = icon.scale,
        y_scale = icon.scale,
        target = {x = (x * 2) + (x / 32), y = (y * 2) + (y / 32)},
        surface = sprite_surface
      }
    )

    table.insert(
      state.data.icons,
      {
        id = icon.sprite,
        x = (x * 64) + x,
        y = (y * 64) + y
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
  local y_resolution = (rows * 64) + rows
  local y_position = rows - 1 + (rows / 64)

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
