# Python–Godot parity matrix

Last verified: 2026-09-03 with Godot 4.7.1.

Run every scenario from the repository root:

```powershell
python tools/parity/compare_runners.py
```

The command must exit successfully before changing simulation behavior or
scenario balance. The comparator reports the first differing snapshot path and
uses an absolute numeric tolerance of `1e-9`.

| Scenario | Primary contract covered |
| --- | --- |
| `empty_sources_20_ticks` | Source accumulation, capacity data, fixed stepping, initial state. |
| `machine_batch` | Input consumption at start, no progress on start tick, efficiency floor, timed output. |
| `partial_food_shortage` | Ordered global food consumption, partial support, population decline. |
| `priority_staffing` | Descending worker priority and ascending node-ID tie-break. |
| `construction_delivery` | Packet capacity, travel, construction delivery, promotion, edge refund. |
| `production_output_block` | Atomic output-capacity block and automatic release of a full-input edge. |
| `delete_inflight_packet` | Cargo loss and transporter refund when deleting a busy edge. |
| `egypt_10_ticks` | Real save v1, active production, construction, settlement and transport continuation. |
| `eg2_10_ticks` | Large real save v1 with ID gaps, 56 nodes and 19 edges. |

## Covered state

Snapshots compare:

- Node identity, type, position and runtime state.
- Inventories and construction progress.
- Active process duration, remaining time and output marker.
- Assigned workers and worker efficiency.
- Directed edge order and type.
- Packet resource, amount and travel progress.
- Empty return progress.
- Global transport inventory.
- Population, housing capacity, food metrics, attractiveness and trend.
- Next node ID, executed step count and simulated seconds.

## Remaining focused scenarios

The full-save fixtures exercise these behaviors, but dedicated minimal fixtures
should still be added when their systems are changed:

- Multiple-output source with one output full.
- Zero-duration machine recipe.
- One-way edge delivery and same-tick relaunch.
- Attractiveness growth and decline modifiers.
- Node deletion with several incident occupied edges.
- Save/load continuation compared after additional ticks.
- Structural unlock fixed-point calculation.

No intentional simulation divergence is currently approved.
