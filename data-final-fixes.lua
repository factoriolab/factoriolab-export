local function check_size(raw)
  for _, obj in pairs(raw) do
    if obj.icon_size == nil and obj.icons and obj.icons[1].scale == 1 then
      obj.order = (obj.order or "") .. "|" .. obj.icons[1].icon_size
    end
  end
end

local function check_size_alt(raw)
  for _, obj in pairs(raw) do
    if obj.icon_size then
      obj.order = (obj.order or "") .. "|" .. obj.icon_size
    else
      obj.order = (obj.order or "") .. "|" .. obj.icons[1].icon_size
    end
  end
end

check_size(data.raw["item"])
check_size(data.raw["fluid"])
check_size(data.raw["recipe"])
check_size_alt(data.raw["item-group"])
check_size_alt(data.raw["technology"])
