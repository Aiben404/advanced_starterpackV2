local ESX = exports['es_extended']:getSharedObject()

local isOpen      = false
local pendingOpen = false
local claimState  = { package = false, vehicle = false }
local starterPed

--- Request a model and block until it loads. Returns false on timeout.
local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 100 do
        Wait(50)
        tries = tries + 1
    end
    return HasModelLoaded(hash)
end

-- ---------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------
local function buildUiData()
    return {
        action     = 'open',
        text       = Config.Text,
        money      = Config.Money,
        items      = Config.Items,
        itemImages = Config.ItemImages,
        vehicle    = {
            enabled = Config.Vehicle.enabled,
            label   = Config.Vehicle.label,
            class   = Config.Vehicle.class,
            seats   = Config.Vehicle.seats,
            image   = Config.Vehicle.image,
        },
        state = claimState,
    }
end

local function doOpen()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(buildUiData())
end

-- Confirm the latest claim state from the server before showing the menu, so a
-- resource restart or stale cache can't render claimed buttons as claimable.
local function openUI()
    if isOpen then return end
    pendingOpen = true
    TriggerServerEvent('advanced_starterpackV2:requestState')
    SetTimeout(1500, function()
        if pendingOpen then
            pendingOpen = false
            doOpen()
        end
    end)
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ---------------------------------------------------------------------------
-- Server sync
-- ---------------------------------------------------------------------------
RegisterNetEvent('advanced_starterpackV2:setState', function(state)
    claimState = state
    SendNUIMessage({ action = 'state', state = state })

    if pendingOpen then
        pendingOpen = false
        doOpen()
    end
end)

RegisterNetEvent('advanced_starterpackV2:notify', function(msg)
    ESX.ShowNotification(msg)
end)

AddEventHandler('esx:playerLoaded', function()
    TriggerServerEvent('advanced_starterpackV2:requestState')
end)

-- Re-sync if the resource restarts while the player is already online.
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('advanced_starterpackV2:requestState')
end)

-- ---------------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------------
RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('claimPackage', function(_, cb)
    TriggerServerEvent('advanced_starterpackV2:claimPackage')
    cb('ok')
end)

RegisterNUICallback('claimVehicle', function(_, cb)
    TriggerServerEvent('advanced_starterpackV2:claimVehicle')
    cb('ok')
end)

-- ---------------------------------------------------------------------------
-- Starter NPC
-- ---------------------------------------------------------------------------
local function spawnStarterPed()
    local npc = Config.Open.npc
    if not npc.enabled then return end

    local hash = joaat(npc.model)
    if not loadModel(hash) then return end

    local c = npc.coords
    starterPed = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetEntityInvincible(starterPed, true)
    SetBlockingOfNonTemporaryEvents(starterPed, true)
    FreezeEntityPosition(starterPed, true)
    SetEntityAsMissionEntity(starterPed, true, true)
    if npc.scenario and npc.scenario ~= '' then
        TaskStartScenarioInPlace(starterPed, npc.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(hash)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(starterPed, {
            {
                name     = 'advanced_starterpackV2_open',
                icon     = 'fa-solid fa-gift',
                label    = 'Open New Citizen Package',
                distance = 2.5,
                onSelect = openUI,
            }
        })
    end
end

CreateThread(function()
    Wait(500)
    spawnStarterPed()
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and starterPed and DoesEntityExist(starterPed) then
        DeleteEntity(starterPed)
    end
end)

-- ---------------------------------------------------------------------------
-- Starter vehicle
-- ---------------------------------------------------------------------------
RegisterNetEvent('advanced_starterpackV2:spawnVehicle', function(model, plate, spawnLoc)
    closeUI()

    local hash = joaat(model)
    if not loadModel(hash) then
        ESX.ShowNotification('Failed to load vehicle model: ' .. tostring(model))
        return
    end

    local x, y, z, heading
    if spawnLoc then
        x, y, z, heading = spawnLoc.x, spawnLoc.y, spawnLoc.z, spawnLoc.w
    else
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 4.0)
        x, y, z, heading = pos.x, pos.y, pos.z, GetEntityHeading(ped)
    end

    local veh = CreateVehicle(hash, x, y, z, heading, true, false)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(hash)

    if Config.Vehicle.teleportIntoVehicle then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
            Wait(100)
        end
        SetPedIntoVehicle(ped, veh, -1)
    end
end)
