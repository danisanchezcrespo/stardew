# Milestone 17 — Time-travelling settlements

The title screen asks **“WHERE DO YOU WANT TO GO TODAY?”** and creates or resumes an independent timeline in one of four destinations.

| Era | Core pressure | Signature loop | Finale |
|---|---|---|---|
| Prehistory | Food, shelter and a tiny clan | Gather branches/flint → craft and select a spear → hunt moving mammoths → preserve meat | Ritual stones |
| Ancient Egypt | Irrigation, food and specialist industry | Nile water → grain/livestock → workshops → bronze, linen and papyrus | River Temple |
| Medieval | Housing and interdependent trades | Wheat → miller/flour → bread; ore → blacksmith/tools → market/coin | Stone keep |
| Mars | Energy, oxygen and hostile resources | Martian ice → staffed melter/water → oxygen → hydroponics/rations | Communications array |

## Shared simulation

- Scenarios choose their own item, recipe, building and campaign registries, terrain, character sheet, terminology and UI palette.
- Each timeline has distinct manual and automatic save files. Loading rejects data from another scenario.
- Houses create a deliberately small population. A resident assigned to a building walks there, enters it during the work shift, becomes its physical worker, gains profession experience and leaves to eat or sleep.
- Staffed production, transport routes, needs, maintenance, environmental modifiers and population capacity are common systems configured by data.
- `DependentActor` represents both cared-for livestock and moving wildlife. Definitions decide food, water, maturation, products, harvest outputs and required hunting tools.

## Controls

- `1–4`: choose Prehistory, Egypt, Medieval or Mars on the destination screen.
- `WASD`: move; mouse wheel: zoom; `Space`: contextual action; `C`: crafting; `Tab`: cycle residents; `Esc`: back.
- Select a resident and use its side panel to assign work or transport. A worker must physically enter a machine before staffed production begins.
- In Prehistory, craft a flint spear, select it in the belt, approach a mammoth and press `Space` twice to complete the hunt.

## Verification

```powershell
Godot --headless --path godot --script res://tests/test_four_era_content.gd
Godot --headless --path godot --script res://tests/test_four_era_runtime.gd
```

The content test validates all registries, campaigns, assets, unique save keys and the spear requirement. The runtime test boots every era and executes the mammoth hunt. The complete suite currently contains 33 passing Godot tests.
