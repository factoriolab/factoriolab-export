utils = {}

-- Sort table by a list of fields
function utils.sort_by(t, n1, n2, n3, n4, n5, n6)
  local function sort_by_func(a, b)
    if a[n1] < b[n1] then
      return true
    elseif n2 and a[n1] == b[n1] then
      if a[n2] < b[n2] then
        return true
      elseif n3 and a[n2] == b[n2] then
        if a[n3] < b[n3] then
          return true
        elseif n4 and a[n3] == b[n3] then
          if a[n4] < b[n4] then
            return true
          elseif n5 and a[n4] == b[n4] then
            if a[n5] < b[n5] then
              return true
            elseif n6 and a[n5] == b[n5] then
              return a[n6] < b[n6]
            end
          end
        end
      end
    end
    return false
  end

  table.sort(t, sort_by_func)
end

-- Round a float to a number of decimals
function utils.round(num, decimals)
  local mult = 10 ^ (decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Convert energy value to kW
function utils.convert_energy(energy)
  if not energy then
    return nil
  end
  return energy / 1000 * 60
end

-- Convert a list to a table by id/name
function utils.to_table(array)
  local table = {}
  for _, obj in pairs(array) do
    table[obj.id] = obj.name
  end
  return table
end

function utils.get_order_info(key)
  local noise_layer_name = "factoriolab-export/" .. key
  local noise_layer = game.noise_layer_prototypes[noise_layer_name]
  if noise_layer == nil then
    return nil, nil
  end
  local hash_id, size = string.match(noise_layer.order, "^(.+)|(.+)$")
  if hash_id and size then
    return tonumber(hash_id), 64 / tonumber(size)
  else
    hash_id = string.match(noise_layer.order, "^(.+)$")
    if hash_id then
      return tonumber(hash_id), nil
    else
      return nil, nil
    end
  end
end

return utils
