local function notify(msg)
  if Config.Notify then
    Config.Notify(msg)
    return
  end
  TriggerEvent("chat:addMessage", { args = { "Promille", msg } })
end

local function getClosestPlayer(max_distance)
  local players = GetActivePlayers()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local closest_player = nil
  local closest_distance = max_distance + 0.01

  for _, player in ipairs(players) do
    if player ~= PlayerId() then
      local target_ped = GetPlayerPed(player)
      local target_coords = GetEntityCoords(target_ped)
      local distance = #(coords - target_coords)
      if distance < closest_distance then
        closest_distance = distance
        closest_player = player
      end
    end
  end

  if closest_player then
    return GetPlayerServerId(closest_player)
  end
  return nil
end

RegisterNetEvent("promille:notify", function(msg)
  notify(msg)
end)

RegisterNetEvent("promille:selectTarget", function()
  local target = getClosestPlayer(Config.MaxDistance)
  if not target then
    notify(Config.Messages.NoPlayer)
    return
  end
  TriggerServerEvent("promille:requestTest", target)
end)

RegisterNetEvent("promille:showResult", function(target_name, value)
  local msg = string.format(Config.Messages.Result, target_name, value)
  notify(msg)
end)
