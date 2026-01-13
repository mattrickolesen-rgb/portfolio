local isOpen = false
local cachedState = nil

local function openApp()
  if isOpen then return end
  isOpen = true
  SetNuiFocus(true, true)
  SendNUIMessage({ type = 'open', state = cachedState })
end

local function closeApp()
  if not isOpen then return end
  isOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'close' })
end

RegisterCommand('polkald', function()
  TriggerServerEvent('polkald:requestState')
  openApp()
end)

RegisterNetEvent('polkald:open', function()
  TriggerServerEvent('polkald:requestState')
  openApp()
end)

RegisterNetEvent('polkald:updateState', function(state)
  cachedState = state
  if isOpen then
    SendNUIMessage({ type = 'state', state = state })
  end
end)

RegisterNetEvent('polkald:incomingCall', function(call)
  cachedState = cachedState or {}
  SendNUIMessage({ type = 'incomingCall', call = call })
end)

RegisterNetEvent('polkald:incomingMessage', function(message)
  SendNUIMessage({ type = 'incomingMessage', message = message })
end)

RegisterNetEvent('polkald:callAnswered', function(payload)
  SendNUIMessage({ type = 'callAnswered', payload = payload })
end)

RegisterNetEvent('polkald:callEnded', function(payload)
  SendNUIMessage({ type = 'callEnded', payload = payload })
end)

RegisterNetEvent('polkald:notify', function(msg)
  SendNUIMessage({ type = 'notify', message = msg })
end)

RegisterNUICallback('close', function(_, cb)
  closeApp()
  cb('ok')
end)

RegisterNUICallback('requestState', function(_, cb)
  TriggerServerEvent('polkald:requestState')
  cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
  TriggerServerEvent('polkald:sendMessage', data)
  cb('ok')
end)

RegisterNUICallback('startCall', function(data, cb)
  TriggerServerEvent('polkald:startCall', data)
  cb('ok')
end)

RegisterNUICallback('answerCall', function(data, cb)
  TriggerServerEvent('polkald:answerCall', data)
  cb('ok')
end)

RegisterNUICallback('endCall', function(data, cb)
  TriggerServerEvent('polkald:endCall', data)
  cb('ok')
end)

RegisterNUICallback('adminAssign', function(data, cb)
  TriggerServerEvent('polkald:adminAssign', data)
  cb('ok')
end)

RegisterNUICallback('adminRemove', function(data, cb)
  TriggerServerEvent('polkald:adminRemove', data)
  cb('ok')
end)

CreateThread(function()
  if not Config.UseLBPhoneExport then return end
  if GetResourceState(Config.LBPhoneResource) ~= 'started' then return end

  local ok = pcall(function()
    exports[Config.LBPhoneResource]:AddCustomApp({
      identifier = Config.LBPhoneAppId,
      name = Config.LBPhoneAppLabel,
      description = 'Kontakt politiet',
      developer = 'Rigspolitiet',
      icon = Config.LBPhoneAppIcon,
      ui = 'html/index.html',
      onOpen = function()
        TriggerServerEvent('polkald:requestState')
        openApp()
      end
    })
  end)

  if not ok then
    print('[polkald] LB phone export failed. Use /polkald to open the app.')
  end
end)
