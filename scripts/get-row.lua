return function()
  local last_row, last_col, last_group, last_subgroup = 0, 0
  return function(obj)
    if obj.group == last_group then
      if obj.subgroup ~= last_subgroup then
        last_row = last_row + 1
        last_col = 0
      end
    else
      last_row = 0
      last_col = 0
    end

    last_group = obj.group
    last_subgroup = obj.subgroup
    last_col = last_col + 1
    return last_row
  end
end
