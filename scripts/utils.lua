utils = {}

function utils.get_row_fn()
  local last_row, last_group, last_subgroup = 0
  return function(obj)
    if obj.group == last_group then
      if obj.subgroup ~= last_subgroup then
        last_row = last_row + 1
      end
    else
      last_row = 0
    end

    last_group = obj.group
    last_subgroup = obj.subgroup
    return last_row
  end
end

function utils.convert_emissions(emissions, energy)
  return emissions and energy and emissions * energy * 1000 * 60 or nil
end

function utils.convert_energy(energy)
  return energy and energy / 1000 * 60 or nil
end

return utils
