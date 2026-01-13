# POLkald

LB Phone police contact app for vRP.

## Install

1. Put this resource in your server resources folder.
2. Add to server.cfg:
   start polkald
3. Ensure vRP is started before this resource.
4. Use /polkald to open the app.

## LB Phone integration

This resource attempts to register a custom LB Phone app with the export:

exports['lb-phone']:AddCustomApp({ ... })

If your lb-phone version uses a different export, update `client.lua` to match, or call the app with:

TriggerEvent('polkald:open')

and wire that event to your LB Phone custom app entry.

## Roles and departments

Rigspolitichefen (user id 2526) can assign roles and departments in-app.
Update group names in `config.lua` to match your vRP groups.

Roles:
- Politi
- Leder (can go on Vagthavende)
- oeversteledelse (can go on Vagtchef)

Departments:
- Politiskolen
- BerdskGroen
- BerdskGul
- RKS
- OperativFaerdsel
- SagsAdmin
- NaerPolitiet
- Vagtcentralen

## Notes

- Calls are routed to all users with the Vagtcentralen department first. If none or no answer, they fall back to the Leder role (Vagthavende).
- Emergency 112 uses the same flow and is marked as emergency in the UI.
