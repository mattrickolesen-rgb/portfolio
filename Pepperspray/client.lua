local effectActive = false

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function getTargetPlayer(maxDist)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = rotationToDirection(camRot)
    local dest = camCoords + direction * maxDist

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        dest.x, dest.y, dest.z,
        12,
        PlayerPedId(),
        0
    )

    local _, hit, _, _, entityHit = GetShapeTestResult(ray)
    if hit == 1 and entityHit ~= 0 and IsEntityAPed(entityHit) and IsPedAPlayer(entityHit) then
        return entityHit
    end

    return nil
end

local function playSprayAnim()
    local ped = PlayerPedId()
    local dict = 'weapons@misc@spray'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'spray_low', 8.0, -8.0, 1000, 48, 0.0, false, false, false)
        RemoveAnimDict(dict)
    end
end

local function playSprayFx(ped)
    if Config.PtfxAsset and Config.PtfxName then
        RequestNamedPtfxAsset(Config.PtfxAsset)
        local timeout = GetGameTimer() + 1000
        while not HasNamedPtfxAssetLoaded(Config.PtfxAsset) and GetGameTimer() < timeout do
            Wait(10)
        end

        if HasNamedPtfxAssetLoaded(Config.PtfxAsset) then
            UseParticleFxAssetNextCall(Config.PtfxAsset)
            StartParticleFxNonLoopedOnEntity(
                Config.PtfxName,
                ped,
                0.0, 0.35, 0.6,
                0.0, 0.0, GetEntityHeading(ped),
                Config.PtfxScale or 0.6,
                false, false, false
            )
            RemoveNamedPtfxAsset(Config.PtfxAsset)
        end
    end

    if Config.SoundName and Config.SoundSet then
        PlaySoundFromEntity(-1, Config.SoundName, ped, Config.SoundSet, false, 0)
    end
end

RegisterNetEvent('pepperspray:notify', function(msg)
    notify(msg)
end)

RegisterNetEvent('pepperspray:use', function()
    if effectActive then
        notify('You are already affected by pepperspray.')
        return
    end

    playSprayAnim()
    playSprayFx(PlayerPedId())
    Wait(200)

    local targetPed = getTargetPlayer(Config.Range)
    if not targetPed then
        notify('No target in range.')
        return
    end

    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
    if not targetId then
        notify('Target not found.')
        return
    end

    TriggerServerEvent('pepperspray:hit', targetId)
end)

RegisterNetEvent('pepperspray:effects', function(duration)
    if effectActive then
        return
    end

    effectActive = true

    StartScreenEffect('DrugsTrevorClownsFight', 0, true)
    SetTimecycleModifier('hud_def_blur')
    ShakeGameplayCam('DRUNK_SHAKE', 1.0)

    local endTime = GetGameTimer() + duration
    CreateThread(function()
        while GetGameTimer() < endTime do
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 44, true)
            Wait(0)
        end

        StopScreenEffect('DrugsTrevorClownsFight')
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        effectActive = false
    end)
end)
