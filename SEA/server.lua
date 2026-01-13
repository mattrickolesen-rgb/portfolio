local ESX = nil

CreateThread(function()
    if exports and exports['es_extended'] then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)

local function isPolice(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then
        return false
    end
    return Config.PoliceJobs[xPlayer.job.name] == true
end

local function randomBloodType()
    return Config.BloodTypes[math.random(1, #Config.BloodTypes)]
end

local function makeHash(prefix, identifier)
    return prefix .. '-' .. tostring(GetHashKey(identifier .. Config.DnaSalt))
end

local function getOrCreateProfile(identifier, cb)
    exports.oxmysql:single('SELECT * FROM sea_forensics_profiles WHERE identifier = ?', { identifier }, function(row)
        if row then
            cb(row)
            return
        end

        local bloodType = randomBloodType()
        local dnaHash = makeHash('DNA', identifier)
        local fingerprintHash = makeHash('FP', identifier)

        exports.oxmysql:execute(
            'INSERT INTO sea_forensics_profiles (identifier, blood_type, dna_hash, fingerprint_hash, updated_at) VALUES (?, ?, ?, ?, NOW())',
            { identifier, bloodType, dnaHash, fingerprintHash },
            function()
                cb({
                    identifier = identifier,
                    blood_type = bloodType,
                    dna_hash = dnaHash,
                    fingerprint_hash = fingerprintHash
                })
            end
        )
    end)
end

ESX.RegisterServerCallback('sea_forensics:getProfile', function(source, cb, targetId)
    if not isPolice(source) then
        cb(nil, 'Not authorized')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb(nil, 'Target not found')
        return
    end

    getOrCreateProfile(xTarget.identifier, function(profile)
        cb(profile, nil)
    end)
end)

ESX.RegisterServerCallback('sea_forensics:getSamples', function(source, cb)
    if not isPolice(source) then
        cb({})
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({})
        return
    end

    exports.oxmysql:execute(
        'SELECT id, sample_type, dna_hash, fingerprint_hash, blood_type, collected_at FROM sea_forensics_samples WHERE collected_by = ? ORDER BY collected_at DESC LIMIT 20',
        { xPlayer.identifier },
        function(rows)
            cb(rows or {})
        end
    )
end)

ESX.RegisterServerCallback('sea_forensics:collectFingerprint', function(source, cb, targetId)
    if not isPolice(source) then
        cb(nil, 'Not authorized')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then
        cb(nil, 'Target not found')
        return
    end

    getOrCreateProfile(xTarget.identifier, function(profile)
        local fingerprint = profile.fingerprint_hash or makeHash('FP', xTarget.identifier)
        exports.oxmysql:insert(
            'INSERT INTO sea_forensics_samples (sample_type, dna_hash, fingerprint_hash, collected_by, collected_from, collected_at) VALUES (?, ?, ?, ?, ?, NOW())',
            { 'fingerprint', nil, fingerprint, xPlayer.identifier, xTarget.identifier },
            function(insertId)
                cb({
                    id = insertId,
                    sample_type = 'fingerprint',
                    fingerprint_hash = fingerprint
                }, nil)
            end
        )
    end)
end)

ESX.RegisterServerCallback('sea_forensics:collectSaliva', function(source, cb, targetId)
    if not isPolice(source) then
        cb(nil, 'Not authorized')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then
        cb(nil, 'Target not found')
        return
    end

    getOrCreateProfile(xTarget.identifier, function(profile)
        exports.oxmysql:insert(
            'INSERT INTO sea_forensics_samples (sample_type, dna_hash, fingerprint_hash, collected_by, collected_from, collected_at) VALUES (?, ?, ?, ?, ?, NOW())',
            { 'saliva', profile.dna_hash, nil, xPlayer.identifier, xTarget.identifier },
            function(insertId)
                cb({
                    id = insertId,
                    sample_type = 'saliva',
                    dna_hash = profile.dna_hash
                }, nil)
            end
        )
    end)
end)

ESX.RegisterServerCallback('sea_forensics:collectBlood', function(source, cb, targetId)
    if not isPolice(source) then
        cb(nil, 'Not authorized')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then
        cb(nil, 'Target not found')
        return
    end

    getOrCreateProfile(xTarget.identifier, function(profile)
        exports.oxmysql:insert(
            'INSERT INTO sea_forensics_samples (sample_type, dna_hash, fingerprint_hash, blood_type, collected_by, collected_from, collected_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
            { 'blood', profile.dna_hash, nil, profile.blood_type, xPlayer.identifier, xTarget.identifier },
            function(insertId)
                cb({
                    id = insertId,
                    sample_type = 'blood',
                    dna_hash = profile.dna_hash,
                    blood_type = profile.blood_type
                }, nil)
            end
        )
    end)
end)

ESX.RegisterServerCallback('sea_forensics:compareSample', function(source, cb, sampleId, targetId)
    if not isPolice(source) then
        cb(false, 'Not authorized')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb(false, 'Target not found')
        return
    end

    exports.oxmysql:single(
        'SELECT id, dna_hash FROM sea_forensics_samples WHERE id = ? AND sample_type = ?',
        { sampleId, 'saliva' },
        function(sample)
            if not sample then
                cb(false, 'Sample not found')
                return
            end

            getOrCreateProfile(xTarget.identifier, function(profile)
                cb(sample.dna_hash == profile.dna_hash, nil)
            end)
        end
    )
end)

ESX.RegisterServerCallback('sea_forensics:setBloodType', function(source, cb, targetId, bloodType)
    if not isPolice(source) then
        cb(false, 'Not authorized')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb(false, 'Target not found')
        return
    end

    getOrCreateProfile(xTarget.identifier, function()
        exports.oxmysql:execute(
            'UPDATE sea_forensics_profiles SET blood_type = ?, updated_at = NOW() WHERE identifier = ?',
            { bloodType, xTarget.identifier },
            function()
                cb(true, nil)
            end
        )
    end)
end)
