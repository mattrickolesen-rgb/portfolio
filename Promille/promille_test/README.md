# Promille Test (vRP)

Simple item-based promille tester for vRP. Police uses an item to test the nearest player and gets a numeric result.

## Install
1) Drop the `promille_test` folder into your `resources/`.
2) Add `ensure promille_test` to your `server.cfg`.

## vRP item setup
Add the item manually in your vRP `cfg/items.lua` (example):

```
["promilletester"] = {
  "Promilletester",
  "Bruges af politiet til at teste promille.",
  function(args)
    TriggerEvent("promille:useTest", args.player)
  end
}
```

## Permission (optional)
Set `Config.RequiredPermission` in `config.lua` to a vRP permission (default: `police.breathalyzer`).
Leave it empty to skip permission checks.

## Promille from alcohol items
Call this event when a player drinks alcohol:

```
TriggerServerEvent("promille:drink", 0.10)
```

You can adjust decay rate in `config.lua` (`Config.PromilleDecayPerMinute`).
