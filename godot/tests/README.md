# Tests

Simulation parity and regression tests belong here.

Once Godot 4 is available, run the definition loader test from the repository
root with:

```powershell
godot --headless --path godot --script res://tests/test_definition_registry.gd
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
