local ESX = nil

local inCCTV = false
local camIndex = 1
local camHandle = nil
local recording = false
local snapshots = {}
local nuiOpen = false
local currentCamId = nil
local cameras = {}
local placedCameras = {}

local tabletObject = nil

local function notify(msg)
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName(msg)
  EndTextCommandThefeedPostTicker(false, false)
end

local function showHelp(text)
  BeginTextCommandDisplayHelp('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayHelp(0, false, false, -1)
end

local function hasScreenshotBasic()
  return GetResourceState('screenshot-basic') == 'started'
end

local function hasPermission()
  if not ESX then
    return false
  end
  local data = ESX.GetPlayerData()
  if not data or not data.job then
    return false
  end
  return data.job.name == Config.JobName
end

local function buildBaseCameras()
  local list = {}
  for i, cam in ipairs(Config.Cameras) do
    local copy = {}
    for k, v in pairs(cam) do
      copy[k] = v
    end
    copy.id = 'base_' .. tostring(i)
    table.insert(list, copy)
  end
  return list
end

local baseCameras = buildBaseCameras()

local function rebuildCameras()
  cameras = {}
  for _, cam in ipairs(baseCameras) do
    table.insert(cameras, cam)
  end
  for _, cam in ipairs(placedCameras) do
    table.insert(cameras, cam)
  end
  if camIndex > #cameras then
    camIndex = 1
  end
end

local function destroyCam()
  if camHandle then
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(camHandle, false)
    camHandle = nil
  end
  ClearFocus()
  ClearTimecycleModifier()
end

local function setCam(index)
  local camData = cameras[index]
  if not camData then
    return
  end

  currentCamId = camData.id
  destroyCam()

  camHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  SetCamCoord(camHandle, camData.coords.x, camData.coords.y, camData.coords.z)
  SetCamRot(camHandle, camData.rot.x, camData.rot.y, camData.rot.z, 2)
  SetCamFov(camHandle, camData.fov or Config.DefaultFov)
  SetCamActive(camHandle, true)
  RenderScriptCams(true, false, 0, true, true)
  SetFocusArea(camData.coords.x, camData.coords.y, camData.coords.z, 0.0, 0.0, 0.0)
  SetTimecycleModifier('CAMERA_secuirity')
  SetTimecycleModifierStrength(0.8)

  notify(('CCTV: %s'):format(camData.label))
end

local function stopRecording()
  recording = false
end

local function pushSnapshot(camId, data)
  if not camId then
    return
  end
  snapshots[camId] = snapshots[camId] or {}
  table.insert(snapshots[camId], 1, data)
  if #snapshots[camId] > Config.MaxSnapshotsPerCam then
    table.remove(snapshots[camId])
  end
end

local function captureSnapshot()
  if not hasScreenshotBasic() then
    notify('CCTV: screenshot-basic mangler')
    recording = false
    return
  end

  local camId = currentCamId
  exports['screenshot-basic']:requestScreenshot(function(data)
    if data and type(data) == 'string' then
      pushSnapshot(camId, data)
    end
  end)
end

local function startRecordingLoop()
  CreateThread(function()
    while inCCTV and recording do
      captureSnapshot()
      Wait(Config.SnapshotIntervalMs)
    end
  end)
end

local function openRewatch()
  local camShots = snapshots[currentCamId] or {}
  if #camShots == 0 then
    notify('CCTV: ingen snapshots endnu')
    return
  end

  nuiOpen = true
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = 'open',
    camera = cameras[camIndex].label,
    images = camShots
  })
end

local function closeRewatch()
  nuiOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
end

local function rotationToDirection(rotation)
  local adjusted = vector3(
    math.rad(rotation.x),
    math.rad(rotation.y),
    math.rad(rotation.z)
  )
  return vector3(
    -math.sin(adjusted.z) * math.abs(math.cos(adjusted.x)),
    math.cos(adjusted.z) * math.abs(math.cos(adjusted.x)),
    math.sin(adjusted.x)
  )
end

local function getCameraPlacement()
  local camCoords = GetGameplayCamCoord()
  local camRot = GetGameplayCamRot(2)
  local direction = rotationToDirection(camRot)
  local distance = Config.PlaceDistance
  local dest = camCoords + (direction * distance)
  local ray = StartShapeTestRay(
    camCoords.x, camCoords.y, camCoords.z,
    dest.x, dest.y, dest.z,
    -1,
    PlayerPedId(),
    0
  )
  local _, hit, endCoords = GetShapeTestResult(ray)
  if hit ~= 1 then
    return nil, nil
  end
  return endCoords, camRot
end

local function keyboardInput(title, defaultText, maxLen)
  AddTextEntry('CCTV_INPUT', title)
  DisplayOnscreenKeyboard(1, 'CCTV_INPUT', '', defaultText or '', '', '', '', maxLen or 25)
  while UpdateOnscreenKeyboard() == 0 do
    Wait(0)
  end
  if UpdateOnscreenKeyboard() == 1 then
    return GetOnscreenKeyboardResult()
  end
  return nil
end

local function placeCamera()
  if not hasPermission() then
    notify('CCTV: ingen adgang')
    return
  end

  local coords, rot = getCameraPlacement()
  if not coords then
    notify('CCTV: kan ikke placere her')
    return
  end

  local label = keyboardInput('Camera label', 'CCTV', 25)
  if not label or label == '' then
    label = 'CCTV'
  end

  TriggerServerEvent('cctv:addCamera', {
    label = label,
    coords = coords,
    rot = vector3(rot.x, rot.y, rot.z),
    fov = Config.DefaultFov
  })

  notify('CCTV: kamera placeret')
end

local function attachTablet()
  if tabletObject then
    return
  end

  local ped = PlayerPedId()
  local model = `prop_cs_tablet`
  local dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'

  RequestModel(model)
  while not HasModelLoaded(model) do
    Wait(0)
  end

  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
    Wait(0)
  end

  tabletObject = CreateObject(model, 1.0, 1.0, 1.0, true, true, false)
  AttachEntityToEntity(
    tabletObject,
    ped,
    GetPedBoneIndex(ped, 60309),
    0.03, 0.002, -0.03,
    10.0, 160.0, 0.0,
    true, false, false, false, 2, true
  )
  TaskPlayAnim(ped, dict, 'base', 8.0, -8.0, -1, 49, 0, false, false, false)
end

local function detachTablet()
  if tabletObject then
    DeleteEntity(tabletObject)
    tabletObject = nil
  end
  ClearPedTasks(PlayerPedId())
end

local function enterCCTV()
  if inCCTV then
    return
  end

  if not hasPermission() then
    notify('CCTV: ingen adgang')
    return
  end

  if #cameras == 0 then
    notify('CCTV: ingen kameraer konfigureret')
    return
  end

  inCCTV = true
  camIndex = 1

  local ped = PlayerPedId()
  FreezeEntityPosition(ped, true)

  attachTablet()
  setCam(camIndex)

  CreateThread(function()
    while inCCTV do
      DisableAllControlActions(0)
      EnableControlAction(0, Config.ExitKey, true)
      EnableControlAction(0, Config.SwitchLeftKey, true)
      EnableControlAction(0, Config.SwitchRightKey, true)
      EnableControlAction(0, Config.RecordKey, true)
      EnableControlAction(0, Config.RewatchKey, true)
      EnableControlAction(0, Config.PlaceKey, true)

      if IsDisabledControlJustPressed(0, Config.ExitKey) then
        break
      end

      if not nuiOpen then
        if IsDisabledControlJustPressed(0, Config.SwitchLeftKey) then
          camIndex = camIndex - 1
          if camIndex < 1 then
            camIndex = #cameras
          end
          setCam(camIndex)
        elseif IsDisabledControlJustPressed(0, Config.SwitchRightKey) then
          camIndex = camIndex + 1
          if camIndex > #cameras then
            camIndex = 1
          end
          setCam(camIndex)
        elseif IsDisabledControlJustPressed(0, Config.RecordKey) then
          recording = not recording
          if recording then
            notify('CCTV: optagelse start')
            startRecordingLoop()
          else
            notify('CCTV: optagelse stop')
          end
        elseif IsDisabledControlJustPressed(0, Config.RewatchKey) then
          openRewatch()
        elseif IsDisabledControlJustPressed(0, Config.PlaceKey) then
          placeCamera()
        end
      end

      local recordText = recording and 'ON' or 'OFF'
      showHelp(('CCTV | Venstre/Hojre: skift | G: optag %s | F7: rewatch | E: place | Backspace: exit'):format(recordText))
      Wait(0)
    end

    closeRewatch()
    stopRecording()
    destroyCam()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    detachTablet()
    inCCTV = false
  end)
end

RegisterCommand(Config.Command, function()
  if inCCTV then
    return
  end
  enterCCTV()
end, false)

RegisterNUICallback('close', function(_, cb)
  closeRewatch()
  cb('ok')
end)

RegisterNetEvent('cctv:syncCameras', function(list)
  placedCameras = list or {}
  rebuildCameras()
end)

RegisterNetEvent('cctv:cameraAdded', function(camData)
  if type(camData) ~= 'table' then
    return
  end
  table.insert(placedCameras, camData)
  rebuildCameras()
end)

RegisterNetEvent('esx:setJob', function(job)
  local data = ESX and ESX.GetPlayerData() or nil
  if data then
    data.job = job
  end
end)

CreateThread(function()
  while ESX == nil do
    if GetResourceState('es_extended') == 'started' then
      ESX = exports['es_extended']:getSharedObject()
    else
      TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
    Wait(0)
  end

  while ESX.GetPlayerData().job == nil do
    Wait(100)
  end

  TriggerServerEvent('cctv:requestCameras')
end)
