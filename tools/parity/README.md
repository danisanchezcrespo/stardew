# Simulation parity runner

This directory contains tooling for comparing the immutable Python reference
implementation with the Godot port.

The runner accepts a JSON scenario, performs its actions against
`legacy_simcity`, and writes a normalized simulation snapshot to stdout.
It never imports or depends on the legacy UI.

Scenarios may set a repository-relative `definitions` path. When omitted, both
runners use the canonical Ancient Egypt definitions. Alternate files are used
only for focused engine cases that the production scenario cannot express.

```powershell
python tools/parity/legacy_runner.py tools/parity/scenarios/egypt_10_ticks.json
```

Use `--output PATH` to write the snapshot to a file. Paths inside a scenario
are resolved relative to the repository root. Supported actions are:

- `load_save`: replace the current state from a version 1 savegame.
- `create_node`: create a node and optionally bind its ID with `as`.
- `connect`: connect two IDs or aliases with an explicit edge type.
- `set_inventory`: replace or merge a node inventory.
- `set_node_state`: force a valid runtime state when preparing a focused fixture.
- `set_workers`: set the current population before the next tick.
- `step`: execute a fixed `dt` one or more times.
- `round_trip_save`: serialize and reload the current state in memory.
- `delete_node`: delete a node through the legacy controller behavior.
- `delete_edge`: delete an edge by its current list index.

The output deliberately excludes camera, selection, notification, and canvas
state. Nodes are ordered by ID, numeric values are rounded consistently, and a
SHA-256 digest covers the normalized simulation payload.

## Cross-engine comparison

Once Godot is available, execute all JSON scenarios in `scenarios/` in both engines:

```powershell
python tools/parity/compare_runners.py
```

Set `GODOT_BIN` or pass `--godot PATH` when the executable is not discoverable.
The comparator reports the first differing JSON path and uses an absolute
numeric tolerance of `1e-9` by default.

See `docs/PARITY_MATRIX.md` for the behavior covered by each scenario and the
remaining focused cases.
