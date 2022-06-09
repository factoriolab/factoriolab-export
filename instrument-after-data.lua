local noise_layers = {} -- Use fake noise layers to store sprite info
local prefix = "factoriolab-export/"

local icon_hash, icon_hash_id = {}, 0
local function get_icon_hash(obj)
  if not obj.icon and not obj.icons then
    return -1
  end

  local serialized = string.format("%s.%s.%s", obj.icon or "", obj.icon_size or "", obj.icon_mipmaps or "")
  if obj.icons then
    for _, icon in pairs(obj.icons) do
      serialized =
        string.format(
        "%s,%s.%s.%s.%s.%s.%s.%s.%s.%s.%s",
        serialized,
        icon.icon,
        icon.icon_size,
        icon.scale or "",
        icon.icon_mipmaps or "",
        (icon.shift and icon.shift[1]) or "",
        (icon.shift and icon.shift[2]) or "",
        (icon.tint and (icon.tint.r or icon.tint[1])) or "",
        (icon.tint and (icon.tint.g or icon.tint[2])) or "",
        (icon.tint and (icon.tint.b or icon.tint[3])) or "",
        (icon.tint and (icon.tint.a or icon.tint[4])) or ""
      )
    end
  end
  if not icon_hash[serialized] then
    icon_hash[serialized] = icon_hash_id
    icon_hash_id = icon_hash_id + 1
  end
  return icon_hash[serialized]
end

local function check_overflow(obj)
  if not obj.icons or #obj.icons < 2 then
    return nil
  end
  local base = obj.icons[1]
  local size = (base.icon_size or obj.icon_size) * (base.scale or 1)
  if base.icon_size == 64 and base.scale == nil then
    size = 32
  end
  local compare_size = size

  for _, icon in pairs(obj.icons) do
    if icon.shift then
      local ico_size = (icon.icon_size or obj.icon_size) * (icon.scale or 1)
      if icon.icon_size == 64 and icon.scale == nil then
        ico_size = 32
      end
      local a = (icon.shift[1] < 0 and icon.shift[1] * -1) or icon.shift[1]
      local b = (icon.shift[2] < 0 and icon.shift[2] * -1) or icon.shift[2]
      local offset = (a > b and a) or b
      local width = ((ico_size / 2) + offset) * 2

      if width > compare_size then
        compare_size = (width / size) * 32
      end
    end
  end

  if compare_size ~= size then
    -- log(obj.name .. ": " .. compare_size)
    -- for _, i in pairs(obj.icons) do
    --   log(
    --     "icon: " ..
    --       i.icon ..
    --         ", mips: " ..
    --           (i.icon_mipmaps or "nil") ..
    --             ", size: " ..
    --               (i.icon_size or "nil") ..
    --                 ", scale: " ..
    --                   (i.scale or "nil") .. ", shift: " .. ((i.shift and (i.shift[1] .. "|" .. i.shift[2])) or "nil")
    --   )
    -- end
    return compare_size
  else
    return nil
  end
end

local function check_size(key, store_as)
  raw = data.raw[key]
  for _, obj in pairs(raw) do
    local order = get_icon_hash(obj)
    local size = check_overflow(obj)
    if not size and obj.icons and obj.icons[1].scale == 1 then
      size = obj.icons[1].icon_size
    end
    if size then
      order = order .. "|" .. size
    end
    local name = prefix .. (store_as or key) .. "/" .. obj.name
    table.insert(noise_layers, {name = name, order = order, type = "noise-layer"})
  end
end

local function check_size_alt(key)
  raw = data.raw[key]
  for _, obj in pairs(raw) do
    local order = get_icon_hash(obj)
    if obj.icons and obj.icons[1].icon_size then
      order = order .. "|" .. (obj.icons[1].icon_size * (obj.icons[1].scale or 1))
    else
      order = order .. "|" .. obj.icon_size
    end
    local name = prefix .. key .. "/" .. obj.name
    table.insert(noise_layers, {name = name, order = order, type = "noise-layer"})
  end
end

check_size("item")
check_size("ammo", "item")
check_size("armor", "item")
check_size("capsule", "item")
check_size("gun", "item")
check_size("item-with-entity-data", "item")
check_size("module", "item")
check_size("rail-planner", "item")
check_size("repair-tool", "item")
check_size("spidertron-remote", "item")
check_size("tool", "item")
check_size("fluid")
check_size("recipe")
check_size_alt("item-group")
check_size_alt("technology")

data:extend(noise_layers)
