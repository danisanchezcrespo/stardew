# Legacy simulation parity specification

Status: audited from the Python reference implementation on 2026-09-02.

This document records the observable behavior that the first Godot milestone
must reproduce. It is a description of the current prototype, not a promise
that every behavior should survive into the final game. Differences in the
Godot port must be intentional, tested, and listed in the divergence log.

## Scope and source of truth

The parity target is the simulation implemented primarily by:

- `legacy_simcity/editor/app_controller.py`
- `legacy_simcity/model/`
- `legacy_simcity/persistence/savegame_io.py`
- `legacy_simcity/core/constants.py`
- `legacy_simcity/data/entities.json`

`entities.json` is the active Ancient Egypt definition file. `egypt.json` and
`eg2.json` are version 1 savegames, not entity-definition files. The file
`entities - copia.json` is an older Spanish variant and is not the initial
parity target.

Rendering, mouse handling, camera state, notifications, and Tk widgets are out
of scope except where they currently trigger or mutate simulation state.

## Runtime model

### Entity definitions

An entity definition contains:

| Field | Type/default | Meaning |
| --- | --- | --- |
| `id` | required string | Stable entity type identifier. |
| `label` | `id` | Display name. |
| `color` | `#888888` | Legacy display color. |
| `construction_cost` | `{}` | Resources that must be delivered before completion. |
| `initial_amounts` | `{}` | Inventory assigned on immediate creation or completion. |
| `max_amounts` | `{}` | Per-resource inventory capacities. Missing means unlimited. |
| `recipe_inputs` | `{}` | One batch of consumed inputs. |
| `recipe_outputs` | `{}` | One batch of produced outputs. |
| `source_rate_per_sec` | `0.0` | Multiplier used by source entities. |
| `process_time_sec` | `0.0` | Base duration of a machine batch. |
| `shared_resource_modifiers` | `{}` | Currently recognizes `workers_max` and `attractiveness`. |
| `workers_required` | `0.0` | Workers required for full machine speed. |
| `worker_priority` | `0` | Higher values receive workers first. |
| `min_worker_efficiency` | `0.0` | Operating-efficiency floor. |

All numeric maps are converted to floating point during loading. Duplicate IDs
are not rejected; a later definition replaces the lookup entry while every ID
is still appended to palette order.

A source is inferred, not explicitly declared: it has at least one recipe
output and no recipe inputs. An entity with no outputs never produces.

### Edge type definitions

| Field | Type/default | Meaning |
| --- | --- | --- |
| `id` | required string | Stable transport type identifier. |
| `label` | `id` | Display name. |
| `color` | `#FFD966` | Legacy display color. |
| `speed` | `50.0` | World-distance units travelled per second. |
| `capacity_per_trip` | `10.0` | Maximum packet amount. |
| `mode` | `one_way` | Either `one_way` or `ping_pong`. |
| `transport_resource` | `""` | Resource used to construct an edge. Empty means unlimited. |
| `units_per_edge` | `1.0` | Amount removed from the global transport pool. Must be positive. |
| `initial_pool_units` | `0.0` | Amount added to the initial global pool. |

The loader accepts edge definitions under `edges` or the older `edge_types`
key. It validates only `mode` and positive `units_per_edge`; it does not reject
negative speed, capacity, rates, costs, or duplicate IDs.

### Entity instances

Each node stores its integer ID, entity type, continuous world position, state,
inventory, construction delivery map, active-process timing, first output name,
and worker allocation. Canvas identifiers are transient legacy UI data.

States are:

- `UNDER_CONSTRUCTION`: accepts only missing construction resources.
- `READY`: currently idle or blocked.
- `RUNNING`: currently producing or advancing a batch.

State is descriptive and recalculated by processing; it is not a player-set
on/off switch.

### Transport instances

An edge stores source ID, target ID, edge type, at most one outbound packet,
and optional empty return progress. A packet contains one resource, one amount,
and normalized travel progress.

## Creation and graph rules

Node IDs start at 1 and increase monotonically. A node with any construction
cost starts `UNDER_CONSTRUCTION`, with zero progress for every cost and an empty
inventory. A cost-free source starts `RUNNING`; any other cost-free node starts
`READY` with a copy of `initial_amounts`.

Edges are directed. Self-edges and duplicate edges in the same direction are
rejected; the reverse direction is allowed. Connection compatibility requires
at least one intersection between the source node's non-transport outputs and
the target's acceptable resources. Under-construction nodes expose no outputs.

Creating an edge spends `units_per_edge` from its transport resource pool.
Deleting an edge or a node refunds that amount. Cargo currently in flight is
lost when its edge or node is deleted.

## Exact simulation-step order

One call to `simulation_step(dt)` performs these operations in this order:

1. Rebuild shared settlement statistics.
2. Consume food and update population.
3. Assign workers.
4. Process sources and machines.
5. Advance existing outbound packets and empty returns.
6. Launch new packets on idle edges.
7. Promote completed construction.
8. Advance the legacy notification timer.

The Tk application requests a tick every 100 ms, measures wall-clock delta,
and caps a running tick at 0.2 seconds. No simulation step occurs while paused.
The Godot parity harness should use an explicit fixed `dt`; UI frame timing must
not be part of the simulation API.

Consequences of ordering that tests must preserve:

- Inputs delivered during a tick cannot start a process until the next tick.
- A packet launched during a tick does not move until the next tick.
- A construction completed by delivery is promoted at the end of that tick.
- Population consumes food before the current tick's production is available.
- Workers are allocated after population changes and before production.

## Settlement and workers

Every tick, all completed nodes contribute their `workers_max` and
`attractiveness` modifiers. Under-construction nodes contribute nothing.
Population is immediately clamped to the rebuilt maximum.

Food is the literal resource ID `food`. Before consumption, `food_available`
is set to the total held by completed nodes. Required food is:

`workers_current * 0.05 * dt`

Food is removed from completed node inventories in node insertion order. The
support ratio is consumed divided by required, clamped to `[0, 1]`; it is `1`
when the requirement is effectively zero.

With full food support, population changes by:

`0.12 * (1 + attractiveness * 0.05) * (workers_max - current) * dt`

With a shortage, it changes by:

`-0.18 * max(0.15, 1 - attractiveness * 0.04) * (1 - support_ratio) * current * dt`

The result is clamped to `[0, workers_max]`. Population can grow from exactly
zero when housing exists, and its first growth tick requires no food because
food demand is calculated from the pre-growth population.

Worker allocation resets every tick. Completed nodes requiring workers are
sorted by descending `worker_priority`, then ascending node ID. Each receives
as many remaining workers as possible. Raw efficiency is assigned/required.
Machines without a worker requirement have efficiency `1`. Construction has
efficiency `0`.

At production time, `min_worker_efficiency` is applied as a floor. Therefore a
machine with zero assigned workers can still run when this value is positive.
Sources do not apply worker efficiency.

## Production

### Sources

A source with a non-positive rate becomes `READY`. Otherwise it runs if at
least one non-transport output has spare capacity or any output is a transport
resource. Each output receives:

`recipe_output_amount * source_rate_per_sec * dt`

Normal outputs are clamped to capacity. Transport-resource outputs bypass the
node inventory and are added directly to the global transport pool.

The source's capacity gate uses “any output has room”, so a multi-output source
can continue while some outputs are full; excess for those outputs is silently
discarded by clamping.

### Machines

A normal machine is evaluated as follows:

1. Zero effective staffing makes it `READY`.
2. Insufficient room for a complete output batch makes it `READY`.
3. An active process subtracts `dt * effective_staffing` from remaining time.
4. When remaining time reaches zero, every output is deposited as one batch.
5. With no active process, every input must satisfy `available + 0.0001 >= required`.
6. Inputs are consumed immediately when a process starts.
7. The new process is not advanced during its starting tick.
8. A zero-duration process produces immediately.

Output capacity is checked even for a process already underway, so filling its
output inventory externally can pause that process. Output capacity is checked
as an atomic batch across every non-transport output. Transport outputs go to
the global pool. `active_process_output_name` stores only the first output ID
and is informational; completion uses the current definition's full output map.

## Transport

Travel progress per second is `edge_speed / max(1, euclidean_distance)`. There
is no separate global transfer-rate limit despite the unused
`EDGE_TRANSFER_RATE_PER_SEC` constant.

An idle edge considers acceptable target resources in definition-map order. It
launches the first resource that has both positive source inventory and positive
receivable target capacity after subtracting all matching in-flight reservations.
The packet amount is the minimum of available inventory, receivable capacity,
and trip capacity. Cargo leaves the source immediately.

On arrival, construction cargo fills only the remaining cost; normal cargo is
clamped to the target capacity. Reservation logic should prevent routine
overflow. `ping_pong` edges must complete an equally long empty return before
launching again. `one_way` edges become idle immediately after delivery but,
because advancement precedes launching, can relaunch later in the same tick.

Construction-only incoming edges are automatically removed and refunded once
they can no longer carry a still-missing construction resource. Edges carrying
a packet are retained until delivery. Incoming idle edges are also removed and
refunded when construction is promoted.

## Construction

Construction has no time or labor component. It is completed solely through
resource delivery over edges. Progress for each resource is capped at its cost.
Overall progress is the sum of capped delivered amounts divided by the sum of
cost amounts.

After all costs pass the `0.0001` tolerance, the node becomes `READY` and every
`initial_amounts` entry is assigned to its inventory. Construction materials
are not transferred into inventory. Incoming idle construction edges are
removed and refunded. A newly completed source remains `READY` until the next
production step changes it to `RUNNING`.

## Structural unlock behavior

Legacy palette unlocking is based on types placed anywhere in the graph, not
on current stock, completed construction, connectivity, or operational state.
For each placed type, its requirements are the union of construction costs and
recipe inputs. Starting from types with no requirements, the algorithm computes
a fixed point of reachable output resource IDs. A new entity is unlocked when
all of its requirements are in that set.

This is UI progression logic but affects which nodes the legacy UI permits the
player to create, so the parity harness should cover it separately from the
headless simulation.

## Persistence contract

Savegame version is exactly `1`; missing version becomes `0` and is rejected.
A save contains all nodes, edges, packet and return progress, graph-facing
editor state, transport pool, and settlement state. `next_node_id` is rebuilt as
one greater than the highest loaded ID.

The loader clears the graph before deserializing. It does not validate entity
or edge references against the active registry. Drag and pan gestures are reset,
but selection, notification, camera, and simulation mode are restored. The
entity definitions themselves are not embedded in the save, so changing
`entities.json` changes the behavior of an existing save.

The Godot simulation save should eventually exclude presentation-only state,
but the parity serializer must be able to normalize and compare every
simulation-relevant version 1 field.

## Ancient Egypt reference data

The active file contains 35 entity definitions and 4 transport types. Its
resource graph is closed: every construction or recipe input is produced by an
entity. Final or otherwise unconsumed normal outputs are `food`, `treasure`,
`temple_complex`, `obelisk`, `step_pyramid`, and `great_pyramid`.

Transport types are `PORTER`, `SLED`, `OX_CART`, and `RIVER_BOAT`. Their resource
IDs are respectively `porter`, `sled`, `ox_cart`, and `river_boat`. The initial
pool contains two porters and two sleds; the other types must be produced.

Bundled saves provide useful regression fixtures:

| Save | Nodes | Edges | Notable state |
| --- | ---: | ---: | --- |
| `egypt.json` | 29 | 4 | 26 running, 3 under construction, population about 15.32/20. |
| `eg2.json` | 56 | 19 | 16 running, 40 ready, population about 75.44/80. |

## Known quirks and port policy

The following are observable legacy behaviors, not automatically desirable
final-game rules:

1. Simulation logic lives in a UI controller rather than a standalone engine.
2. Floating-point results and node insertion order affect outcomes.
3. Transport resources are a global pool while ordinary resources are local.
4. Minimum efficiency can create labor-free production.
5. Population can spontaneously grow from zero.
6. Source output ratios can lose excess output when only some capacities are full.
7. Deleting an occupied edge destroys its cargo.
8. Construction consumes no time or workers.
9. Unlocking counts placed and unfinished entity types.
10. Saves depend on mutable external definitions and have no migration path.
11. Several numeric fields accept invalid negative values.
12. `EDGE_TRANSFER_RATE_PER_SEC` is defined but unused.

For milestone 1, the default is to reproduce these behaviors in parity tests.
Any correction must be recorded below with a rationale and paired legacy/Godot
expectations.

## Planned Godot subsystem boundaries

| Godot component | Responsibility |
| --- | --- |
| `SimulationDefinitionRegistry` | Load and validate scenario definitions. |
| `SimulationState` | Time, nodes, edges, transport pools, and settlement state. |
| `SimulationEngine` | Execute an explicit deterministic step in the legacy order. |
| `InventorySystem` | Capacity checks, local transfers, and global consumption. |
| `WorkforceSystem` | Shared stats, population change, and worker allocation. |
| `ProductionSystem` | Source generation and atomic machine batches. |
| `TransportSystem` | Reservations, packet launch, travel, return, and delivery. |
| `ConstructionSystem` | Delivery progress, promotion, and edge release. |
| `SavegameCodec` | Versioned simulation serialization and migration. |
| `ParityRunner` | Load fixtures, apply commands and ticks, emit normalized JSON. |

None of these components should depend on `Node2D`, scene-tree timing, input,
camera, or rendering.

## Required parity scenarios

Before milestone 1 can close, automated tests must cover:

1. Definition defaults, numeric conversion, and validation failures.
2. Cost-free source creation and constructed-machine creation.
3. Source accumulation, capacity blocking, and transport-pool production.
4. Machine input consumption, timing, worker scaling, and batch output blocking.
5. Worker priority tie-breaking and minimum-efficiency behavior.
6. Full-food growth, partial-food decline, attractiveness modifiers, and zero population.
7. One-way delivery, ping-pong return, distance scaling, and reservations.
8. Multi-resource construction, promotion, and automatic edge refunds.
9. Structural unlock fixed-point calculation.
10. Save/load round trip during active production and packet transport.
11. Deterministic continuation from both bundled Ancient Egypt saves.
12. Deletion of nodes and edges, including refund and in-flight cargo behavior.

Numeric comparisons should use an explicit tolerance and stable ordering by node
ID and edge list position. Each fixture must specify `dt` values rather than use
wall-clock time.

## Divergence log

No intentional Godot divergences have been approved yet.
