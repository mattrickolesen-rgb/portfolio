# Pepperspray (ox_inventory)

Simple pepperspray item for FiveM with blur effect.

## Install

1) Drop this resource in your server resources folder (e.g. `resources/[local]/pepperspray`).
2) Add to `server.cfg`:

```
ensure pepperspray
```

3) Add item to `ox_inventory` items list (`ox_inventory/data/items.lua`):

```
['pepperspray'] = {
    label = 'Pepper Spray',
    weight = 200,
    stack = true,
    close = true,
    description = 'Short range self-defense spray'
},
```

## Config

Edit `config.lua` for range, duration, and cooldown.

Particles and sound are configurable in `config.lua` (ptfx asset/name and sound set/name).
