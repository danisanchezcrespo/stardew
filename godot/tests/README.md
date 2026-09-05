# Tests

Simulation parity and regression tests belong here.

Once Godot 4 is available, run the definition loader test from the repository
root with:

```powershell
godot --headless --path godot --script res://tests/test_definition_registry.gd
```

Calendar, collections, building upgrades, and technology trees:

```bash
godot --headless --path godot --script res://tests/test_settlement_progression.gd
```

Spatial primitives can be checked independently with:

```powershell
godot --headless --path godot --script res://tests/test_spatial_primitives.gd
```

Placement and occupancy can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_world_grid.gd
```

The executable debug scene can be smoke-tested with:

```powershell
godot --headless --path godot --script res://tests/test_world_debug_scene.gd
```

Player movement, facing, camera and collision can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_player_movement.gd
```

Player atlas dimensions, per-frame clipping and the mammoth atlas can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_graphical_qa.gd
```

Chicken egg production, safe interaction and flock replacement can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_animal_husbandry.gd
```

Item definitions, inventory capacity, targeting and pickup can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_pickup_inventory.gd
```

Recipe loading, transactional crafting and the crafting submenu can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_crafting.gd
```

The complete craft, select, preview and place loop can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_gameplay_placement.gd
```

Placed crate targeting, deposit and withdrawal can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_storage_interaction.gd
```

Physical construction supply, work and completion can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_construction.gd
```

Physical machine input, timed production and output collection can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_machine.gd
```

Directed routes, visible porter trips and safe transfers can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_logistics.gd
```

Finite population, job priority and production staffing can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_workforce.gd
```

Machine wear, breakdown safety and local repair can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_machine_maintenance.gd
```

Egypt vertical-slice objective progression can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_egypt_campaign.gd
```

Physical-world JSON save and fresh-session restoration can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_save.gd
```

Data-driven Egypt and Mesopotamia physical scenarios can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_physical_scenarios.gd
```

Ten-thousand-tick physical production stability can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_long_session.gd
```

Discrete camera zoom and fullscreen bindings can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_display_controls.gd
```

Fresh-save critical-path resource balance can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_vertical_slice_balance.gd
```

Four-era content isolation, campaign assets and the prehistoric spear requirement can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_four_era_content.gd
```

Booting Prehistory, Ancient Egypt, Medieval and Mars plus the executable mammoth-hunt loop can be checked with:

```powershell
godot --headless --path godot --script res://tests/test_four_era_runtime.gd
```
