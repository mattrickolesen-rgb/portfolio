local Proxy = module('vrp', 'lib/Proxy')
local Tunnel = module('vrp', 'lib/Tunnel')

vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP', 'dms')

local dms = {}
Tunnel.bindInterface('dms', dms)

local function prepareQueries()
  local tableName = Config.identityTable
  local idCol = Config.identityIdColumn
  local firstnameCol = Config.identityFirstnameColumn
  local lastnameCol = Config.identityLastnameColumn
  local phoneCol = Config.identityPhoneColumn
  local regCol = Config.identityRegColumn

  local getById = string.format('SELECT * FROM %s WHERE %s = @id LIMIT 1', tableName, idCol)
  local getPhone = string.format('SELECT %s FROM %s WHERE %s = @id LIMIT 1', phoneCol, tableName, idCol)
  local search = string.format(
    'SELECT * FROM %s WHERE %s LIKE @term OR %s LIKE @term OR %s LIKE @term OR %s LIKE @term LIMIT %s',
    tableName,
    firstnameCol,
    lastnameCol,
    regCol,
    phoneCol,
    tonumber(Config.maxResults) or 25
  )

  vRP._prepare('dms/get_by_id', getById)
  vRP._prepare('dms/get_phone', getPhone)
  vRP._prepare('dms/search', search)
end

prepareQueries()

local cases = {}
local caseSeq = 0
local records = {}

local function nextCaseId()
  caseSeq = caseSeq + 1
  return caseSeq
end

local function canUse(source)
  local user_id = vRP.getUserId({source})
  if not user_id then return false end
  if Config.permission and Config.permission ~= '' then
    return vRP.hasPermission({user_id, Config.permission})
  end
  return true
end

function dms.canOpen()
  return canUse(source)
end

function dms.search(term, byId)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end

  if byId and tonumber(term) then
    local rows = vRP.query('dms/get_by_id', { id = tonumber(term) })
    return { ok = true, results = rows or {} }
  end

  if not term or #term < (Config.searchMinLength or 2) then
    return { ok = false, error = 'too_short' }
  end

  local rows = vRP.query('dms/search', { term = '%' .. term .. '%' })
  return { ok = true, results = rows or {} }
end

local function getActiveCase(user_id)
  for _, item in pairs(cases) do
    if item.status == 'taken' and item.assigned_to == user_id then
      return item
    end
  end
  return nil
end

local function applyJail(target_id, minutes)
  local target = vRP.getUserSource({target_id})
  if not target then
    return false, 'offline'
  end

  if vRPclient and vRPclient.setJailTime then
    vRPclient.setJailTime(target, { minutes })
    return true
  end

  if vRPclient and vRPclient.jail then
    vRPclient.jail(target, { minutes })
    return true
  end

  return false, 'no_jail_handler'
end

local function applyFine(target_id, amount)
  if vRP.tryFullPayment then
    return vRP.tryFullPayment({ target_id, amount })
  end

  if vRP.tryPayment then
    return vRP.tryPayment({ target_id, amount })
  end

  return false
end

local function getPhoneNumber(user_id)
  local rows = vRP.query('dms/get_phone', { id = user_id })
  if not rows or not rows[1] then return nil end
  return rows[1][Config.identityPhoneColumn]
end

local function sendPhoneMessage(user_id, message)
  if not Config.phone or not Config.phone.enabled then
    return false, 'disabled'
  end

  local phone = getPhoneNumber(user_id)
  if not phone or phone == '' then
    return false, 'no_phone'
  end

  local sender = Config.phone.sender or 'Domstolen'
  if Config.phone.mode == 'export' then
    local ok, err = pcall(function()
      exports[Config.phone.resource][Config.phone.export](phone, sender, message)
    end)
    if not ok then return false, err end
    return true
  end

  if Config.phone.useClientEvent then
    local src = vRP.getUserSource({user_id})
    if not src then return false, 'offline' end
    TriggerClientEvent(Config.phone.event, src, sender, message, phone)
    return true
  end

  TriggerEvent(Config.phone.event, phone, sender, message)
  return true
end

local function addRecord(target_id, entry)
  if not records[target_id] then
    records[target_id] = {}
  end
  table.insert(records[target_id], entry)
end

function dms.getQueue()
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local queue = {}
  local active = getActiveCase(user_id)

  for _, item in pairs(cases) do
    if item.status == 'open' then
      table.insert(queue, item)
    end
  end

  table.sort(queue, function(a, b) return a.id < b.id end)
  return { ok = true, queue = queue, active = active }
end

function dms.addCase(target_id, target_name)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local tId = tonumber(target_id)
  if not tId then return { ok = false, error = 'bad_target' } end

  local id = nextCaseId()
  local item = {
    id = id,
    target_id = tId,
    target_name = target_name or 'Ukendt',
    created_by = user_id,
    status = 'open',
    created_at = os.time()
  }
  cases[id] = item
  return { ok = true, case = item }
end

function dms.takeCase(case_id)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  if getActiveCase(user_id) then
    return { ok = false, error = 'already_active' }
  end

  local id = tonumber(case_id)
  local item = id and cases[id] or nil
  if not item or item.status ~= 'open' then
    return { ok = false, error = 'not_found' }
  end

  item.status = 'taken'
  item.assigned_to = user_id
  item.taken_at = os.time()
  return { ok = true, active = item }
end

function dms.punish(case_id, action, value, reason, verdict, notes)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local id = tonumber(case_id)
  local item = id and cases[id] or nil
  if not item or item.status ~= 'taken' or item.assigned_to ~= user_id then
    return { ok = false, error = 'not_active' }
  end

  local amount = tonumber(value) or 0
  local finalVerdict = verdict or 'guilty'
  if finalVerdict == 'not_guilty' then
    return { ok = false, error = 'not_guilty' }
  end
  local ok = false
  local err = nil

  if action == 'jail' then
    ok, err = applyJail(item.target_id, amount)
  elseif action == 'fine' then
    ok = applyFine(item.target_id, amount)
    if not ok then err = 'payment_failed' end
  else
    return { ok = false, error = 'bad_action' }
  end

  if not ok then
    return { ok = false, error = err or 'failed' }
  end

  item.status = 'closed'
  item.closed_by = user_id
  item.closed_at = os.time()
  item.result = { action = action, value = amount, reason = reason or '', verdict = finalVerdict, notes = notes or '' }
  addRecord(item.target_id, item.result)
  return { ok = true }
end

function dms.closeCase(case_id, verdict, notes)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local id = tonumber(case_id)
  local item = id and cases[id] or nil
  if not item or item.status ~= 'taken' or item.assigned_to ~= user_id then
    return { ok = false, error = 'not_active' }
  end

  local finalVerdict = verdict or 'not_guilty'

  item.status = 'closed'
  item.closed_by = user_id
  item.closed_at = os.time()
  item.result = { action = 'none', value = 0, reason = '', verdict = finalVerdict, notes = notes or '' }

  if finalVerdict == 'guilty' then
    addRecord(item.target_id, item.result)
  end
  return { ok = true }
end

function dms.quickFine(target_id, target_name, amount, message)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local tId = tonumber(target_id)
  local fineAmount = tonumber(amount) or 0
  if not tId or fineAmount <= 0 then
    return { ok = false, error = 'bad_input' }
  end

  local ok = applyFine(tId, fineAmount)
  if not ok then
    return { ok = false, error = 'payment_failed' }
  end

  if message and message ~= '' then
    sendPhoneMessage(tId, message)
  end

  addRecord(tId, { action = 'fine', value = fineAmount, reason = '', verdict = 'guilty', notes = message or '' })
  return { ok = true }
end

function dms.sendSms(target_id, target_name, message)
  if not canUse(source) then return { ok = false, error = 'no_permission' } end
  local user_id = vRP.getUserId({source})
  if not user_id then return { ok = false, error = 'no_user' } end

  local tId = tonumber(target_id)
  if not tId or not message or message == '' then
    return { ok = false, error = 'bad_input' }
  end

  local ok = sendPhoneMessage(tId, message)
  if not ok then
    return { ok = false, error = 'sms_failed' }
  end

  return { ok = true }
end
