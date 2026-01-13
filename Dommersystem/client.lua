local Tunnel = module('vrp', 'lib/Tunnel')
local dmsS = Tunnel.getInterface('dms', 'dms')

local nuiOpen = false

local function setOpen(state)
  nuiOpen = state
  SetNuiFocus(state, state)
  SendNUIMessage({ action = state and 'open' or 'close' })
end

RegisterCommand('dommer', function()
  local ok = dmsS.canOpen()
  if ok then
    setOpen(true)
  end
end)

RegisterKeyMapping('dommer', 'Aabn dommermenu', 'keyboard', 'F6')

RegisterNUICallback('close', function(_, cb)
  setOpen(false)
  cb({ ok = true })
end)

RegisterNUICallback('search', function(data, cb)
  local term = data.term or ''
  local byId = data.byId or false

  local result = dmsS.search(term, byId)
  cb(result)
end)

RegisterNUICallback('getQueue', function(_, cb)
  local result = dmsS.getQueue()
  cb(result)
end)

RegisterNUICallback('addCase', function(data, cb)
  local result = dmsS.addCase(data.target_id, data.target_name)
  cb(result)
end)

RegisterNUICallback('takeCase', function(data, cb)
  local result = dmsS.takeCase(data.case_id)
  cb(result)
end)

RegisterNUICallback('punish', function(data, cb)
  local result = dmsS.punish(data.case_id, data.action, data.value, data.reason, data.verdict, data.notes)
  cb(result)
end)

RegisterNUICallback('closeCase', function(data, cb)
  local result = dmsS.closeCase(data.case_id, data.verdict, data.notes)
  cb(result)
end)

RegisterNUICallback('quickFine', function(data, cb)
  local result = dmsS.quickFine(data.target_id, data.target_name, data.amount, data.message)
  cb(result)
end)

RegisterNUICallback('sendSms', function(data, cb)
  local result = dmsS.sendSms(data.target_id, data.target_name, data.message)
  cb(result)
end)
