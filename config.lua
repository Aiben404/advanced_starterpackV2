Config = {}

-- ============================================================
--  HOW PLAYERS OPEN THE MENU
--  Claims are tracked per CHARACTER (xPlayer.identifier). In an ESX
--  multicharacter setup every character has a unique identifier, so
--  character 1, 2 and 3 each get their own one-time claim automatically.
-- ============================================================
Config.Open = {
    -- Interactable NPC ped. Players use ox_target on the ped to open the menu.
    npc = {
        enabled = true,
        model   = 'a_m_y_business_02',            -- ped model
        coords  = vec4(-1033.4358, -2738.8940, 20.1693, 63.9454), -- x, y, z, heading (default: LSIA airport)
        scenario = 'WORLD_HUMAN_CLIPBOARD',        -- idle animation ('' to disable)
    },
}

-- ============================================================
--  PACKAGE HEADER TEXT (shown in the UI)
-- ============================================================
Config.Text = {
    Title    = 'New Citizen Package',
    Subtitle = 'Welcome to the city. Claim your starter rewards and begin your journey.',
    PackageBadge = 'Starter Package',
    VehicleBadge = 'Starter Vehicle',
}

-- ============================================================
--  MONEY REWARDS
-- ============================================================
Config.Money = {
    cash = 30000,   -- shown as "Money"  ($30,000)
    bank = 10000,   -- shown as "Bank"   ($10,000)
}

-- ============================================================
--  ITEM REWARDS
--  icon = an emoji used ONLY as a fallback if the item image can't load
--         (see Config.ItemImages below).
--  These render as tiles in the same order listed here.
-- ============================================================
Config.Items = {
    { name = 'water',   label = 'Water',      count = 10, icon = '💧' },
    { name = 'burger',  label = 'Burger',     count = 10, icon = '🍔' },
    { name = 'radio',   label = 'Radio',      count = 1,  icon = '📻' },
    { name = 'bandage', label = 'Bandage',    count = 10, icon = '🩹' },
    { name = 'fixkit',  label = 'Repair Kit', count = 2,  icon = '🧰' },
}

-- ============================================================
--  ITEM IMAGES (use real inventory images instead of emojis)
--  The image filename is taken from each item's `name` above, so
--  e.g. 'water' -> water.png in the folder you set below.
--
--  `path` is a NUI url pointing at ox_inventory's image folder:
--     'nui://ox_inventory/web/images/'
--
--  If an image is missing/fails to load, the tile falls back to the
--  emoji `icon` set on that item above.
-- ============================================================
Config.ItemImages = {
    enabled = true,
    path    = 'nui://ox_inventory/web/images/',
    ext     = '.png',
}

-- ============================================================
--  STARTER VEHICLE
-- ============================================================
Config.Vehicle = {
    enabled  = true,
    model    = 'adder',          -- spawn name of the car (change to your custom "SERVER CITY" model)
    label    = 'SERVER CITY CAR',
    class    = 'Super Class',
    seats    = 2,

    -- Vehicle preview image shown in the UI (a real image, not the CSS drawing).
    --   1) Put your image file in:  web/img/   (e.g. web/img/vehicle.png)
    --   2) Set the path below relative to the web folder (e.g. 'img/vehicle.png'),
    --      OR use a full https URL (e.g. 'https://i.imgur.com/xxxx.png').
    --   Leave it empty ('') to fall back to the built-in stylised silhouette.
    image = 'https://i.imgur.com/xxxx.png',

    -- Save the vehicle to the ESX `owned_vehicles` garage table so it persists.
    giveToGarage = true,
    garageType   = 'car',        -- column `type` in owned_vehicles

    -- Spawn the vehicle out immediately after claiming.
    spawnOnClaim = true,

    -- Teleport the player into the driver seat of the vehicle right after it spawns.
    teleportIntoVehicle = true,

    -- WHERE the vehicle spawns when claimed.
    --   useFixedSpawn = true  -> always spawn at `spawnLocation` below (a set garage/lot).
    --   useFixedSpawn = false -> spawn right in front of the player wherever they are.
    useFixedSpawn = true,
    spawnLocation = vec4(-1034.5402, -2728.5762, 19.7155, 241.1932), -- x, y, z, heading (default: near LSIA)

    -- Give keys through a car-lock / key system when the vehicle is claimed.
    giveKeys  = true,
    -- Which key system to use:
    --   'wasabi_carlock' -> exports.wasabi_carlock:GiveKey(source, plate)  (your setup)
    --   'none'           -> don't give keys
    keySystem = 'wasabi_carlock',
}

-- ============================================================
--  NOTIFICATIONS
-- ============================================================
Config.Notify = {
    packageClaimed = 'You collected your Starter Package!',
    packageAlready = 'You already collected your Starter Package.',
    vehicleClaimed = 'Your starter vehicle has been added to your garage!',
    vehicleAlready = 'You already claimed your starter vehicle.',
}

-- ============================================================
--  DISCORD WEBHOOK LOGS
--  Sends a clean embed to Discord each time a player claims.
-- ============================================================
Config.Webhook = {
    enabled = false,                     -- master switch
    url     = '',                        -- paste your Discord webhook URL here

    username = 'Starter Pack',           -- name the message is posted under
    avatar   = '',                       -- optional avatar image url ('' to skip)
    color    = 3066993,                  -- embed accent (decimal). 3066993 = green

    logPackage = true,                   -- log package claims
    logVehicle = true,                   -- log vehicle claims
}
