local ESX = nil

CreateThread(function()
    if exports and exports['es_extended'] then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)

local tabletOpen = false
local currentTarget = nil

local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        TriggerEvent('chat:addMessage', { args = { msg } })
    end
end

local function isPolice()
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then
        return false
    end
    return Config.PoliceJobs[playerData.job.name] == true
end

local function getClosestPlayer(maxDistance)
    local closestPlayer = -1
    local closestDistance = maxDistance or 2.0
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local dist = #(GetEntityCoords(targetPed) - playerCoords)
            if dist < closestDistance then
                closestDistance = dist
                closestPlayer = player
            end
        end
    end

    if closestPlayer == -1 then
        return nil, nil
    end

    return GetPlayerServerId(closestPlayer), closestDistance
end

local function refreshSamples()
    ESX.TriggerServerCallback('sea_forensics:getSamples', function(samples)
        SendNUIMessage({
            action = 'samples',
            samples = samples or {}
        })
    end)
end

local function openTablet()
    if tabletOpen then
        return
    end
    if not isPolice() then
        notify('Ikke adgang.')
        return
    end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    refreshSamples()
end

local function closeTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.TabletCommand, function()
    openTablet()
end, false)

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb({})
end)

RegisterNUICallback('scanNearest', function(_, cb)
    local targetId = getClosestPlayer(2.0)
    if not targetId then
        notify('Ingen personer i nærheden.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:getProfile', function(profile, err)
        if not profile then
            notify(err or 'Kunne ikke hente profil.')
            cb({ ok = false })
            return
        end
        currentTarget = targetId
        SendNUIMessage({
            action = 'profile',
            profile = profile,
            targetId = targetId,
            targetName = GetPlayerName(GetPlayerFromServerId(targetId))
        })
        cb({ ok = true })
    end, targetId)
end)

RegisterNUICallback('collectFingerprint', function(_, cb)
    if not currentTarget then
        notify('Scan en person først.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:collectFingerprint', function(sample, err)
        if not sample then
            notify(err or 'Kunne ikke tage fingeraftryk.')
            cb({ ok = false })
            return
        end
        refreshSamples()
        notify('Fingeraftryk gemt.')
        cb({ ok = true })
    end, currentTarget)
end)

RegisterNUICallback('collectSaliva', function(_, cb)
    if not currentTarget then
        notify('Scan en person først.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:collectSaliva', function(sample, err)
        if not sample then
            notify(err or 'Kunne ikke tage spyt.')
            cb({ ok = false })
            return
        end
        refreshSamples()
        notify('Spytprøve gemt.')
        cb({ ok = true })
    end, currentTarget)
end)

RegisterNUICallback('collectBlood', function(_, cb)
    local targetId = currentTarget
    if not targetId then
        targetId = getClosestPlayer(2.0)
    end
    if not targetId then
        notify('Ingen personer i nærheden.')
        cb({ ok = false })
        return
    end

    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or not IsEntityDead(targetPed) then
        notify('Personen skal være død for at scanne blod.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:collectBlood', function(sample, err)
        if not sample then
            notify(err or 'Kunne ikke scanne blod.')
            cb({ ok = false })
            return
        end
        refreshSamples()
        notify('Blodprøve gemt.')
        cb({ ok = true })
    end, targetId)
end)

RegisterNUICallback('compareSample', function(data, cb)
    if not data or not data.sampleId then
        cb({ ok = false })
        return
    end

    local targetId = currentTarget or getClosestPlayer(2.0)
    if not targetId then
        notify('Scan en person først.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:compareSample', function(match, err)
        if err then
            notify(err)
            cb({ ok = false })
            return
        end
        SendNUIMessage({
            action = 'compareResult',
            match = match,
            sampleId = data.sampleId
        })
        cb({ ok = true })
    end, data.sampleId, targetId)
end)

RegisterNUICallback('setBloodType', function(data, cb)
    if not data or not data.bloodType then
        cb({ ok = false })
        return
    end
    if not currentTarget then
        notify('Scan en person først.')
        cb({ ok = false })
        return
    end

    ESX.TriggerServerCallback('sea_forensics:setBloodType', function(ok, err)
        if not ok then
            notify(err or 'Kunne ikke opdatere blodtype.')
            cb({ ok = false })
            return
        end
        notify('Blodtype opdateret.')
        cb({ ok = true })
    end, currentTarget, data.bloodType)
end)

RegisterKeyMapping(Config.TabletCommand, 'SEA Forensics Tablet', 'keyboard', 'F10')
