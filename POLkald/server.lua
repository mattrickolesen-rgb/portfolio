local Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')

local activeCalls = {}
local callCounter = 0

local function getUserId(source)
  return vRP.getUserId({ source })
end

local function hasGroup(user_id, group)
  if not group then return false end
  return vRP.hasGroup({ user_id, group })
end

local function isRigspolitichefen(user_id)
  return user_id == Config.RigspolitichefenUserId
end

local function hasRole(user_id, roleKey)
  local group = Config.RoleGroups[roleKey]
  return hasGroup(user_id, group)
end

local function hasDepartment(user_id, deptKey)
  local group = Config.DepartmentGroups[deptKey]
  return hasGroup(user_id, group)
end

local function isStaff(user_id)
  for roleKey, _ in pairs(Config.RoleGroups) do
    if hasRole(user_id, roleKey) then return true end
  end
  for deptKey, _ in pairs(Config.DepartmentGroups) do
    if hasDepartment(user_id, deptKey) then return true end
  end
  return false
end

local function getOnlineStaff()
  local users = vRP.getUsers({})
  local staff = {}

  for user_id, source in pairs(users) do
    if isStaff(user_id) then
      local roles = {}
      local depts = {}

      for roleKey, _ in pairs(Config.RoleGroups) do
        if hasRole(user_id, roleKey) then
          table.insert(roles, roleKey)
        end
      end

      for deptKey, _ in pairs(Config.DepartmentGroups) do
        if hasDepartment(user_id, deptKey) then
          table.insert(depts, deptKey)
        end
      end

      table.insert(staff, {
        user_id = user_id,
        source = source,
        name = GetPlayerName(source),
        roles = roles,
        departments = depts
      })
    end
  end

  return staff
end

local function buildState(source)
  local user_id = getUserId(source)
  if not user_id then return {} end

  local roles = {}
  local depts = {}

  for roleKey, _ in pairs(Config.RoleGroups) do
    if hasRole(user_id, roleKey) then
      table.insert(roles, roleKey)
    end
  end

  for deptKey, _ in pairs(Config.DepartmentGroups) do
    if hasDepartment(user_id, deptKey) then
      table.insert(depts, deptKey)
    end
  end

  local departmentsList = {}
  for deptKey, _ in pairs(Config.DepartmentGroups) do
    table.insert(departmentsList, deptKey)
  end

  return {
    user_id = user_id,
    name = GetPlayerName(source),
    isStaff = isStaff(user_id),
    isAdmin = isRigspolitichefen(user_id),
    roles = roles,
    departments = depts,
    departmentsList = departmentsList,
    onlineStaff = getOnlineStaff()
  }
end

local function sendState(source)
  TriggerClientEvent('polkald:updateState', source, buildState(source))
end

local function broadcastState()
  local users = vRP.getUsers({})
  for _, source in pairs(users) do
    sendState(source)
  end
end

local function notify(source, msg)
  TriggerClientEvent('polkald:notify', source, msg)
end

local function getDepartmentTargets(deptKey)
  local users = vRP.getUsers({})
  local targets = {}

  for user_id, source in pairs(users) do
    if hasDepartment(user_id, deptKey) then
      table.insert(targets, { user_id = user_id, source = source })
    end
  end

  return targets
end

local function getRoleTargets(roleKey)
  local users = vRP.getUsers({})
  local targets = {}

  for user_id, source in pairs(users) do
    if hasRole(user_id, roleKey) then
      table.insert(targets, { user_id = user_id, source = source })
    end
  end

  return targets
end

local function startCall(callerSource, kind, targetKey, emergency)
  local callerUserId = getUserId(callerSource)
  if not callerUserId then return end

  callCounter = callCounter + 1
  local callId = callCounter

  local call = {
    id = callId,
    caller = callerSource,
    callerUserId = callerUserId,
    kind = kind,
    targetKey = targetKey,
    emergency = emergency or false,
    answeredBy = nil,
    targets = {},
    fallbackTriggered = false,
    createdAt = os.time()
  }

  activeCalls[callId] = call
  return call
end

local function ringTargets(call, targets, label)
  if #targets == 0 then return false end

  for _, target in ipairs(targets) do
    call.targets[target.source] = true
    TriggerClientEvent('polkald:incomingCall', target.source, {
      id = call.id,
      caller = call.callerUserId,
      callerName = GetPlayerName(call.caller),
      kind = call.kind,
      targetLabel = label,
      emergency = call.emergency
    })
  end

  notify(call.caller, 'Ringer til ' .. label .. '...')
  return true
end

local function triggerFallback(call)
  if call.fallbackTriggered then return end
  call.fallbackTriggered = true

  local targets = getRoleTargets('Leder')
  if #targets == 0 then
    notify(call.caller, 'Ingen Vagthavende er online lige nu.')
    return
  end

  ringTargets(call, targets, 'Vagthavende')
end

RegisterNetEvent('polkald:requestState', function()
  sendState(source)
end)

RegisterNetEvent('polkald:sendMessage', function(data)
  local user_id = getUserId(source)
  if not user_id then return end

  local text = data and data.text
  if not text or text == '' then return end

  local scope = data.scope or 'police'
  local targets = {}

  if scope == 'police' then
    targets = getOnlineStaff()
  elseif scope == 'department' and data.department then
    targets = getDepartmentTargets(data.department)
  elseif scope == 'individual' and data.user_id then
    targets = { { user_id = data.user_id, source = vRP.getUserSource({ data.user_id }) } }
  end

  for _, target in ipairs(targets) do
    if target.source then
      TriggerClientEvent('polkald:incomingMessage', target.source, {
        from = user_id,
        fromName = GetPlayerName(source),
        text = text,
        scope = scope,
        department = data.department
      })
    end
  end

  notify(source, 'Besked sendt.')
end)

RegisterNetEvent('polkald:startCall', function(data)
  local user_id = getUserId(source)
  if not user_id then return end

  local kind = data and data.kind or 'police'
  local emergency = data and data.emergency or false

  if kind == 'police' or kind == 'emergency' then
    local call = startCall(source, 'police', 'Vagtcentralen', emergency)
    if not call then return end

    local vcTargets = getDepartmentTargets('Vagtcentralen')
    if #vcTargets == 0 then
      triggerFallback(call)
    else
      ringTargets(call, vcTargets, 'Vagtcentralen')
      SetTimeout(Config.CallTimeoutSeconds * 1000, function()
        if activeCalls[call.id] and not call.answeredBy then
          triggerFallback(call)
        end
      end)
    end
    return
  end

  if kind == 'department' and data.department then
    local call = startCall(source, 'department', data.department, emergency)
    if not call then return end

    local targets = getDepartmentTargets(data.department)
    if #targets == 0 then
      notify(source, 'Ingen er online i afdelingen lige nu.')
      activeCalls[call.id] = nil
      return
    end

    ringTargets(call, targets, data.department)
    return
  end

  if kind == 'vagthavende' then
    if not hasRole(user_id, 'Leder') then
      notify(source, 'Kun Leder kan ringe til Vagthavende.')
      return
    end
    local call = startCall(source, 'role', 'Vagthavende', emergency)
    if not call then return end

    local targets = getRoleTargets('Leder')
    if #targets == 0 then
      notify(source, 'Ingen Vagthavende er online lige nu.')
      activeCalls[call.id] = nil
      return
    end

    ringTargets(call, targets, 'Vagthavende')
    return
  end

  if kind == 'vagtchef' then
    if not hasRole(user_id, 'Oeversteledelse') then
      notify(source, 'Kun Oeversteledelse kan ringe til Vagtchef.')
      return
    end
    local call = startCall(source, 'role', 'Vagtchef', emergency)
    if not call then return end

    local targets = getRoleTargets('Oeversteledelse')
    if #targets == 0 then
      notify(source, 'Ingen Vagtchef er online lige nu.')
      activeCalls[call.id] = nil
      return
    end

    ringTargets(call, targets, 'Vagtchef')
    return
  end

  if kind == 'individual' and data.user_id then
    local call = startCall(source, 'individual', tostring(data.user_id), emergency)
    if not call then return end

    local targetSource = vRP.getUserSource({ tonumber(data.user_id) })
    if not targetSource then
      notify(source, 'Medarbejder er ikke online.')
      activeCalls[call.id] = nil
      return
    end

    ringTargets(call, { { source = targetSource, user_id = tonumber(data.user_id) } }, 'Medarbejder')
    return
  end
end)

RegisterNetEvent('polkald:answerCall', function(data)
  local callId = data and data.id
  if not callId then return end

  local call = activeCalls[callId]
  if not call then return end

  if call.answeredBy then
    notify(source, 'Opkaldet er allerede besvaret.')
    return
  end

  if not call.targets[source] then
    notify(source, 'Du er ikke modtager af dette opkald.')
    return
  end

  call.answeredBy = source
  notify(call.caller, 'Opkald besvaret af ' .. GetPlayerName(source))
  notify(source, 'Du besvarer opkaldet fra ' .. GetPlayerName(call.caller))

  TriggerClientEvent('polkald:callAnswered', call.caller, {
    id = call.id,
    by = getUserId(source),
    byName = GetPlayerName(source)
  })

  for targetSource, _ in pairs(call.targets) do
    if targetSource ~= source then
      notify(targetSource, 'Opkaldet blev besvaret af en anden.')
    end
  end
end)

RegisterNetEvent('polkald:endCall', function(data)
  local callId = data and data.id
  if not callId then return end

  local call = activeCalls[callId]
  if not call then return end

  activeCalls[callId] = nil
  notify(call.caller, 'Opkald afsluttet.')

  for targetSource, _ in pairs(call.targets) do
    notify(targetSource, 'Opkald afsluttet.')
  end

  TriggerClientEvent('polkald:callEnded', call.caller, { id = callId })
  for targetSource, _ in pairs(call.targets) do
    TriggerClientEvent('polkald:callEnded', targetSource, { id = callId })
  end
end)

RegisterNetEvent('polkald:adminAssign', function(data)
  local user_id = getUserId(source)
  if not user_id or not isRigspolitichefen(user_id) then
    notify(source, 'Kun Rigspolitichefen kan tildele roller.')
    return
  end

  local targetId = tonumber(data and data.user_id)
  if not targetId then return end

  if data.role then
    local group = Config.RoleGroups[data.role]
    if group then
      vRP.addUserGroup({ targetId, group })
    end
  end

  if data.department then
    local group = Config.DepartmentGroups[data.department]
    if group then
      vRP.addUserGroup({ targetId, group })
    end
  end

  notify(source, 'Rolle/afdeling opdateret.')
  broadcastState()
end)

RegisterNetEvent('polkald:adminRemove', function(data)
  local user_id = getUserId(source)
  if not user_id or not isRigspolitichefen(user_id) then
    notify(source, 'Kun Rigspolitichefen kan fjerne roller.')
    return
  end

  local targetId = tonumber(data and data.user_id)
  if not targetId then return end

  if data.role then
    local group = Config.RoleGroups[data.role]
    if group then
      vRP.removeUserGroup({ targetId, group })
    end
  end

  if data.department then
    local group = Config.DepartmentGroups[data.department]
    if group then
      vRP.removeUserGroup({ targetId, group })
    end
  end

  notify(source, 'Rolle/afdeling fjernet.')
  broadcastState()
end)

AddEventHandler('playerDropped', function()
  local user_id = getUserId(source)
  if not user_id then return end

  for callId, call in pairs(activeCalls) do
    if call.caller == source or call.targets[source] then
      activeCalls[callId] = nil
    end
  end
end)
