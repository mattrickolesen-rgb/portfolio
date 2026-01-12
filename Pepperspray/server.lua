local lastUse = {}

local function notify(src, msg)
    TriggerClientEvent('pepperspray:notify', src, msg)
end

exports.ox_inventory:RegisterUsableItem(Config.ItemName, function(source)
    local now = os.time()
    local cooldownSeconds = math.ceil(Config.Cooldown / 1000)
    if lastUse[source] and (now - lastUse[source]) < cooldownSeconds then
        local remaining = cooldownSeconds - (now - lastUse[source])
        notify(source, ('Cooldown: %ds'):format(remaining))
        return
    end

    lastUse[source] = now
    TriggerClientEvent('pepperspray:use', source)
end)

RegisterNetEvent('pepperspray:hit', function(targetId)
    local src = source
    if type(targetId) ~= 'number' then
        return
    end

    if targetId == src then
        return
    end

    local srcPed = GetPlayerPed(src)
    local tgtPed = GetPlayerPed(targetId)
    if srcPed == 0 or tgtPed == 0 then
        return
    end

    local srcCoords = GetEntityCoords(srcPed)
    local tgtCoords = GetEntityCoords(tgtPed)
    if #(srcCoords - tgtCoords) > (Config.Range + 0.5) then
        return
    end

    TriggerClientEvent('pepperspray:effects', targetId, Config.Duration)
end)

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)
