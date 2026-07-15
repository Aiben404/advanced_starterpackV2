local ESX = exports['es_extended']:getSharedObject()

-- In-flight guard: blocks a second claim for the same character + type while
-- the first one is still hitting the database.
local activeClaims = {}

local function lockClaim(identifier, kind)
    local key = identifier .. ':' .. kind
    if activeClaims[key] then return false end
    activeClaims[key] = true
    return true
end

local function unlockClaim(identifier, kind)
    activeClaims[identifier .. ':' .. kind] = nil
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function getClaimState(identifier, cb)
    MySQL.single('SELECT package_claimed, vehicle_claimed FROM user_starterpack WHERE identifier = ?', { identifier }, function(row)
        if row then
            cb({ package = row.package_claimed == 1, vehicle = row.vehicle_claimed == 1 })
        else
            MySQL.insert('INSERT IGNORE INTO user_starterpack (identifier) VALUES (?)', { identifier })
            cb({ package = false, vehicle = false })
        end
    end)
end

-- Make sure a row exists before running a conditional claim UPDATE against it.
local function ensureRow(identifier, cb)
    MySQL.insert('INSERT IGNORE INTO user_starterpack (identifier) VALUES (?)', { identifier }, cb)
end

local function generatePlate()
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local plate = ''
    for _ = 1, 3 do
        local i = math.random(#letters)
        plate = plate .. letters:sub(i, i)
    end
    return plate .. math.random(100, 999)
end

local function giveVehicleKeys(src, plate)
    if not Config.Vehicle.giveKeys then return end

    if Config.Vehicle.keySystem == 'wasabi_carlock' then
        if GetResourceState('wasabi_carlock') == 'started' then
            exports.wasabi_carlock:GiveKey(src, plate)
        else
            print('[advanced_starterpackV2] wasabi_carlock is not started; no keys given.')
        end
    end
end

-- ---------------------------------------------------------------------------
-- Discord webhook
-- ---------------------------------------------------------------------------
local function money(n)
    local s = tostring(math.floor(n))
    while true do
        local next
        s, next = s:gsub('^(%d+)(%d%d%d)', '%1,%2')
        if next == 0 then break end
    end
    return '$' .. s
end

-- Return the player's Discord ID (numeric string) or nil if not linked.
local function getDiscordId(src)
    local id = GetPlayerIdentifierByType(src, 'discord')
    return id and id:gsub('discord:', '') or nil
end

-- Post a clean embed to Discord. `fields` is an array of Discord embed fields.
local function discordLog(title, fields)
    if not Config.Webhook.enabled or not Config.Webhook.url or Config.Webhook.url == '' then return end

    PerformHttpRequest(Config.Webhook.url, function() end, 'POST', json.encode({
        username   = Config.Webhook.username,
        avatar_url = (Config.Webhook.avatar ~= '' and Config.Webhook.avatar) or nil,
        embeds = { {
            title     = title,
            color     = Config.Webhook.color,
            fields    = fields,
            footer    = { text = 'advanced_starterpackV2' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end

-- ---------------------------------------------------------------------------
-- State sync
-- ---------------------------------------------------------------------------
local function sendState(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    getClaimState(xPlayer.identifier, function(state)
        TriggerClientEvent('advanced_starterpackV2:setState', src, state)
    end)
end

RegisterNetEvent('advanced_starterpackV2:requestState', function()
    sendState(source)
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    sendState(playerId)
end)

-- ---------------------------------------------------------------------------
-- Claim: package (money + items)
-- ---------------------------------------------------------------------------
RegisterNetEvent('advanced_starterpackV2:claimPackage', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    if not lockClaim(identifier, 'package') then return end

    ensureRow(identifier, function()
        -- Only the call that flips 0 -> 1 wins, so rewards can't be granted twice.
        MySQL.update('UPDATE user_starterpack SET package_claimed = 1 WHERE identifier = ? AND package_claimed = 0', { identifier }, function(affected)
            if not affected or affected < 1 then
                unlockClaim(identifier, 'package')
                TriggerClientEvent('advanced_starterpackV2:notify', src, Config.Notify.packageAlready)
                return
            end

            if Config.Money.cash and Config.Money.cash > 0 then
                xPlayer.addMoney(Config.Money.cash)
            end
            if Config.Money.bank and Config.Money.bank > 0 then
                xPlayer.addAccountMoney('bank', Config.Money.bank)
            end
            for _, item in ipairs(Config.Items) do
                exports.ox_inventory:AddItem(src, item.name, item.count)
            end

            unlockClaim(identifier, 'package')
            TriggerClientEvent('advanced_starterpackV2:notify', src, Config.Notify.packageClaimed)
            sendState(src)

            if Config.Webhook.logPackage then
                local rewards = {}
                if Config.Money.cash and Config.Money.cash > 0 then rewards[#rewards + 1] = 'Cash: ' .. money(Config.Money.cash) end
                if Config.Money.bank and Config.Money.bank > 0 then rewards[#rewards + 1] = 'Bank: ' .. money(Config.Money.bank) end
                for _, item in ipairs(Config.Items) do
                    rewards[#rewards + 1] = ('%dx %s'):format(item.count, item.label)
                end
                local discord = getDiscordId(src)
                discordLog('Starter Package Claimed', {
                    { name = 'Player',     value = xPlayer.getName(),                    inline = true },
                    { name = 'Server ID',  value = tostring(src),                        inline = true },
                    { name = 'Discord',    value = discord and ('<@' .. discord .. '>') or 'Not linked', inline = true },
                    { name = 'Identifier', value = '`' .. identifier .. '`',             inline = false },
                    { name = 'Rewards',    value = table.concat(rewards, '\n'),          inline = false },
                })
            end
        end)
    end)
end)

-- ---------------------------------------------------------------------------
-- Claim: vehicle
-- ---------------------------------------------------------------------------
RegisterNetEvent('advanced_starterpackV2:claimVehicle', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not Config.Vehicle.enabled then return end

    local identifier = xPlayer.identifier
    if not lockClaim(identifier, 'vehicle') then return end

    ensureRow(identifier, function()
        MySQL.update('UPDATE user_starterpack SET vehicle_claimed = 1 WHERE identifier = ? AND vehicle_claimed = 0', { identifier }, function(affected)
            if not affected or affected < 1 then
                unlockClaim(identifier, 'vehicle')
                TriggerClientEvent('advanced_starterpackV2:notify', src, Config.Notify.vehicleAlready)
                return
            end

            local plate = generatePlate()
            local model = Config.Vehicle.model

            if Config.Vehicle.giveToGarage then
                local props  = { model = joaat(model), plate = plate }
                local stored = Config.Vehicle.spawnOnClaim and 0 or 1
                MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
                    { identifier, plate, json.encode(props), Config.Vehicle.garageType, stored })
            end

            unlockClaim(identifier, 'vehicle')
            giveVehicleKeys(src, plate)

            if Config.Vehicle.spawnOnClaim then
                local spawn = Config.Vehicle.useFixedSpawn and Config.Vehicle.spawnLocation or nil
                TriggerClientEvent('advanced_starterpackV2:spawnVehicle', src, model, plate, spawn)
            end

            TriggerClientEvent('advanced_starterpackV2:notify', src, Config.Notify.vehicleClaimed)
            sendState(src)

            if Config.Webhook.logVehicle then
                local discord = getDiscordId(src)
                discordLog('Starter Vehicle Claimed', {
                    { name = 'Player',     value = xPlayer.getName(),                    inline = true },
                    { name = 'Server ID',  value = tostring(src),                        inline = true },
                    { name = 'Discord',    value = discord and ('<@' .. discord .. '>') or 'Not linked', inline = true },
                    { name = 'Identifier', value = '`' .. identifier .. '`',             inline = false },
                    { name = 'Vehicle',    value = Config.Vehicle.label or model,        inline = true },
                    { name = 'Plate',      value = '`' .. plate .. '`',                  inline = true },
                })
            end
        end)
    end)
end)
