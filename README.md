# advanced_starterpackV2

A New Citizen starter pack for ESX. New players walk up to an NPC and claim a
one-time reward: cash, bank money, items, and a personal vehicle. Everything is
tracked per character in the database, so each claim can only be made once.

## Preview

![Preview 1](https://r2.fivemanage.com/fDUKi7rgEhC1caoH2Yksm/imag11.png)
![Preview 2](https://r2.fivemanage.com/fDUKi7rgEhC1caoH2Yksm/imag22.png)

## Features

- One-time claim per character (money, bank, items, vehicle)
- Clean, minimal NUI with real inventory item images
- Starter vehicle saved to the ESX garage, spawned and handed over on claim
- Optional teleport into the vehicle after it spawns
- Key handoff through wasabi_carlock (or none)
- ox_target NPC to open the menu
- Optional Discord webhook logging for every claim
- Server-authoritative, race-safe claiming (no duplicate rewards)

## Dependencies

- [es_extended](https://github.com/esx-framework/esx_core)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [wasabi_carlock](https://wasabiscripts.com/) *(optional, for keys)*

## Installation

1. Copy `advanced_starterpackV2` into your `resources` folder.
2. Import the database table:
   ```sql
   -- sql/starterpack.sql
   ```
3. Add to your `server.cfg`:
   ```
   ensure advanced_starterpackV2
   ```
4. Configure `config.lua` to taste (rewards, vehicle, NPC location).

## Configuration

All settings live in `config.lua`. The most common ones:

| Setting | Description |
| --- | --- |
| `Config.Open.npc` | NPC model, location and idle scenario |
| `Config.Money` | Cash and bank amounts granted |
| `Config.Items` | Item rewards (name, count, fallback icon) |
| `Config.ItemImages` | Inventory image folder used for the item tiles |
| `Config.Vehicle` | Model, preview image, garage, spawn point, keys |
| `Config.Webhook` | Discord webhook logging for claims |

### Vehicle image

Set `Config.Vehicle.image` to a local file in `web/img/` (e.g. `img/vehicle.png`)
or a full URL. If it can't load, the UI falls back to a built-in placeholder.

### Item images

Item tiles use your inventory's images by filename (`water` → `water.png`).
Point `Config.ItemImages.path` at the image folder, e.g.
`nui://ox_inventory/web/images/`. Missing images fall back to the emoji icon.

## Notes

- Claims are keyed by `xPlayer.identifier`, so every character in a
  multicharacter setup gets its own independent one-time claim.
- Claiming is guarded both in memory and by a conditional SQL update, so
  duplicate rewards are not possible even under spam or lag.
