local vRP = Proxy.getInterface("vRP")

local promille = {}

local function getUserKey(source)
  if vRP and vRP.getUserId then
    return vRP.getUserId(source)
  end
  return source
end

local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

local function addPromilleFor(user_key, amount)
  local current = promille[user_key] or 0.0
  promille[user_key] = current + amount
end

local function getPromilleFor(user_key)
  return promille[user_key] or 0.0
end

RegisterNetEvent("promille:useTest", function(player_src)
  local src = player_src or source
  if not src or src == 0 then
    return
  end
  if vRP and vRP.hasPermission and Config.RequiredPermission and Config.RequiredPermission ~= "" then
    if not vRP.hasPermission(getUserKey(src), Config.RequiredPermission) then
      TriggerClientEvent("promille:notify", src, Config.Messages.NoPermission)
      return
    end
  end

  TriggerClientEvent("promille:selectTarget", src)
end)

RegisterNetEvent("promille:requestTest", function(target_src)
  local src = source
  if vRP and vRP.hasPermission and Config.RequiredPermission and Config.RequiredPermission ~= "" then
    if not vRP.hasPermission(getUserKey(src), Config.RequiredPermission) then
      TriggerClientEvent("promille:notify", src, Config.Messages.NoPermission)
      return
    end
  end
  if not target_src or not GetPlayerName(target_src) then
    return
  end

  local target_key = getUserKey(target_src)
  local value = getPromilleFor(target_key)
  local target_name = GetPlayerName(target_src) or ("ID " .. tostring(target_src))
  TriggerClientEvent("promille:showResult", src, target_name, value)
end)

RegisterNetEvent("promille:drink", function(amount)
  local src = source
  local user_key = getUserKey(src)
  local add = tonumber(amount) or 0.0
  if add <= 0 then return end
  addPromilleFor(user_key, add)
end)

AddEventHandler("playerDropped", function()
  local src = source
  local user_key = getUserKey(src)
  promille[user_key] = nil
end)

CreateThread(function()
  while true do
    Wait(60000)
    for user_key, value in pairs(promille) do
      if value > Config.MinPromille then
        promille[user_key] = clamp(value - Config.PromilleDecayPerMinute, Config.MinPromille, 10.0)
      end
    end
  end
end)
