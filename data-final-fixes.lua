for name, item_group in pairs(data.raw["item-group"]) do
  item_group.order = item_group.order .. "|" .. (item_group.icon_size or 64)
end
for name, technology in pairs(data.raw["technology"]) do
  technology.order = technology.order .. "|" .. (technology.icon_size or 64)
end
