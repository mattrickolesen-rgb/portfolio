local ESX = nil

if GetResourceState('es_extended') == 'started' then
  ESX = exports['es_extended']:getSharedObject()
else
  TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

local placedCameras = {}

local function hasPermission(source)
  if not ESX then
    return false
  end
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer or not xPlayer.job then
    return false
  end
  return xPlayer.job.name == Config.JobName
end

RegisterNetEvent('cctv:requestCameras', function()
  TriggerClientEvent('cctv:syncCameras', source, placedCameras)
end)

RegisterNetEvent('cctv:addCamera', function(camData)
  if type(camData) ~= 'table' then
    return
  end

  if not hasPermission(source) then
    return
  end

  if not camData.coords or not camData.rot then
    return
  end

  camData.label = camData.label or 'CCTV'
  camData.fov = camData.fov or Config.DefaultFov
  camData.id = camData.id or ('placed_' .. tostring(#placedCameras + 1))

  table.insert(placedCameras, camData)
  TriggerClientEvent('cctv:cameraAdded', -1, camData)
end)
