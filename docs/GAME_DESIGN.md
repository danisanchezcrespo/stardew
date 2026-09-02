# STARDew game design foundation

Status: initial product contract for the first playable vertical slice.

Values marked **provisional** are starting points for implementation and must be
tuned through playtesting. They are still concrete enough to prevent the code
from inventing incompatible assumptions.

## Product statement

STARDew is an offline, top-down, tile-based builder and production simulation
played through a physical character. The player does not command the settlement
from an omnipresent cursor. They walk through it, carry resources, build,
operate, automate, diagnose and repair the systems they create.

The game's long-term identity combines:

- The spatial clarity and local interaction of a top-down life simulator.
- The production chains and optimization pressure of an automation game.
- The instability, feedback loops and recoverable crises of a city simulator.

The first complete scenario is Ancient Egypt, but the engine is a reusable
container for scenarios with different resources, art, progression, environment
and failure rules.

## Design pillars

### 1. The player has a body

Distance, access and carrying capacity matter. A useful action normally requires
the character or an assigned agent to reach the relevant place.

### 2. Automation changes the player's job

Early play is manual and concrete. Progress replaces repeated carrying with
routes and workers, then asks the player to design, monitor and repair the larger
system. Automation removes repetition but creates dependencies.

### 3. Every state is legible

The world, animation, sound and UI must explain why a system is working or
stopped. The player should diagnose problems by observing the settlement, with
panels providing detail rather than revealing otherwise invisible rules.

### 4. Failure creates work, not a dead end

Shortages, wear, congestion and environmental events reduce capability and
create priorities. Most failures must have recovery paths and must not erase a
long session without warning.

### 5. Complexity grows faster than convenience

The player's total capability rises, but a larger settlement has more routes,
maintenance, population pressure and cascading dependencies. Expansion is a
decision, not an automatic victory.

### 6. Scenarios are data, systems are reusable

Names such as `BRICK_KILN` must not appear in generic gameplay code. Scenario
data selects reusable behaviors, footprints, recipes, interactions, visuals and
failure profiles.

## Core play loop

```text
observe a need or opportunity
→ travel to the relevant place
→ gather or retrieve resources
→ craft or select a plan
→ place and supply construction
→ operate production manually
→ automate repeated movement or work
→ inspect throughput and bottlenecks
→ expand capacity
→ respond to instability
→ repair, reroute or redesign
```

The loop must work at three scales:

- **Immediate:** pick up, carry, deposit, operate and repair.
- **Tactical:** arrange buildings, routes, storage and worker priorities.
- **Strategic:** choose expansion, redundancy, technology and settlement goals.

## Player verbs

The initial playable vocabulary is deliberately small:

- Move in four directions.
- Face or focus a nearby target.
- Inspect.
- Pick up a resource stack.
- Deposit or withdraw a stack.
- Use a tool or selected item.
- Select, rotate, place or cancel a blueprint.
- Supply and work on a construction site.
- Configure a machine or route locally.
- Repair or maintain an entity.
- Open inventory, crafting, map and settlement views.

Running, combat, stamina, farming minigames and character relationships are not
part of the first vertical slice.

## Physical world contract

### Grid and scale

- Logical tile size: **32×32 pixels, provisional**.
- Rendering may scale integer multiples without changing simulation dimensions.
- Character movement is continuous, not tile-by-tile.
- Placement, terrain and building occupancy use integer grid cells.
- A one-cell prop is smaller than a normal production building.
- Initial machine footprints should usually be 2×2 or 3×2 cells.
- Large civic structures may use irregular footprint masks rather than only
  rectangles.

Every placed entity definition will eventually provide:

- Footprint cells relative to an origin.
- Allowed rotations.
- Terrain requirements.
- Collision mask.
- Interaction points.
- Input, output and service ports.
- Construction and completed visual scenes.

### Movement metrics

- Walk speed: **4 tiles per second, provisional**.
- Character collision width: **about 0.65 tile, provisional**.
- Interaction reach: **1.25 tiles from the character center, provisional**.
- The focused target must be reachable and generally lie in the facing half-plane.
- Diagonal input is normalized even though animation and facing remain
  four-directional.

Walking must establish spatial meaning without becoming dead time. If routine
journeys become tedious, progression should add paths, mounts or transport rather
than making the initial map globally interactive.

### Camera

- Camera follows the player with light smoothing.
- Default framing shows roughly 18×10 logical tiles on a 16:9 screen,
  **provisional**.
- The player can temporarily look ahead or open a strategic map, but cannot
  perform ordinary local actions remotely through it.
- Camera zoom is discrete and clamped to pixel-readable levels.
- Important interactions must remain usable at the default zoom on handheld
  screens.

## Interaction model

The game uses one primary contextual interaction action.

Target selection is deterministic:

1. Valid targets within interaction reach.
2. Targets with a defined interaction point reachable without collision.
3. Preference for the facing direction.
4. Shortest distance to the interaction point.
5. Stable entity ID as final tie-break.

The selected target receives a visible outline or marker and a short prompt such
as `Take wood`, `Open kiln`, `Add materials` or `Repair`.

Holding the interaction action may repeat safe transfers or continuous work.
Destructive actions, blueprint cancellation and demolition require an explicit
confirmation or hold duration.

## Items and inventory

Resources are represented as stacks, not one object per simulation unit.

Initial player inventory:

- 12 general slots, **provisional**.
- 8-slot quick bar, drawn from the same inventory rather than separate storage.
- One item type per stack.
- Data-defined maximum stack sizes.
- No weight system in the first vertical slice.
- Tools may be non-consumable inventory items with durability later.

World pickups are stack entities with item ID, amount and position. Interaction
collects as much as fits; any remainder stays in the world. There is no automatic
vacuum pickup for major resources.

Transfers between player and building must be transactional: no duplication or
loss if capacity changes, a panel closes, or a save occurs.

## Construction experience

Construction is a physical five-stage process:

1. Learn, obtain or craft a blueprint.
2. Enter placement mode near the player.
3. Select a valid footprint and orientation.
4. Deliver required material stacks to the site.
5. Apply construction work until the entity becomes operational.

Legacy simulation parity currently completes construction immediately after the
last material delivery. The physical game will add a data-defined work amount.
This will be an intentional post-parity divergence.

Placement rules:

- The preview snaps to the grid.
- Valid occupied cells are green; blocked cells are red.
- The UI states the first important rejection reason.
- Placement range is local, **4 tiles from the player, provisional**.
- The player may rotate supported blueprints.
- Cancellation returns delivered resources according to a scenario rule; the
  initial rule is full return before work begins and proportional salvage after.

## Machines and production

Simulation inventory remains numeric, but every operational machine exposes a
physical interaction surface and readable state.

World presentation must distinguish at least:

- Producing.
- Missing input.
- Output full.
- Unstaffed or understaffed.
- Under construction.
- Damaged or awaiting maintenance.
- Disabled by the player.

The default machine panel shows recipe, input and output stacks, progress,
staffing and the primary blocking reason. It should not require reading a
spreadsheet to perform basic diagnosis.

## Logistics direction

The first physical logistics system for Ancient Egypt is a porter route:

- A route connects compatible pickup and delivery ports.
- A porter reserves a stack, walks to the source, collects it, walks to the
  destination and deposits it.
- Travel paths and access can fail.
- Carrying capacity and walking speed determine throughput.
- Routes can be prioritized and paused.

The current abstract packet transport remains valuable for deterministic
economics and distant simulation. The physical representation will either drive
the same reservations or substitute an aggregate packet when agents are outside
the active area.

Later route implementations may use sleds, carts, boats, belts, pipes or cables
without replacing the generic reservation and delivery contracts.

## Population direction

Population remains aggregated initially, while a bounded number of visible
workers represent active tasks. This hybrid avoids simulating every resident
individually while preserving the feeling of a lived-in settlement.

Production efficiency will eventually consider both assignment and physical
access. The first playable version may keep housing and food global while making
porter tasks spatial.

## Time and pause

- Simulation uses an explicit fixed tick, initially 10 Hz.
- Rendering and input are independent of simulation ticks.
- The player can pause at any time.
- Full-screen planning, settings and save/load screens pause by default.
- Small local interaction panels do not pause by default.
- No day/night cycle is required for the first vertical slice.
- No action should require waiting without another useful available activity.

## First-session experience

### First five minutes

The player should:

1. Move and understand target highlighting.
2. Pick up wood or clay.
3. Carry and deposit a stack.
4. Place a simple blueprint.
5. See construction respond to delivered material.

### First hour

The player should:

1. Establish water, wood and clay access.
2. Build the first brick-production chain.
3. Construct housing and food production.
4. Experience carrying as a real constraint.
5. Assign or create the first porter route.
6. Observe a bottleneck and improve it.
7. Encounter one warned, recoverable maintenance problem.
8. Complete a small civic objective.

### Long session

The player alternates between expansion, optimization, maintenance, exploration
and goal progress. Automated areas continue to matter because throughput,
population and degradation change their operating conditions.

## First vertical slice boundaries

The Ancient Egypt slice should contain:

- One compact authored map.
- Player movement and local interaction.
- Wood, water, clay, grain and food.
- At least one processed construction material.
- Housing and population pressure.
- Manual carrying and one porter route.
- One maintenance failure and repair recipe.
- One small monument objective.
- Save/load and controller support.

It does not require combat, seasons, relationships, procedural generation,
online features, a full technology tree or final art volume.

## Decision policy

When implementation exposes a conflict, evaluate it in this order:

1. Does it strengthen the physical-player fantasy?
2. Is the state understandable from the world and UI?
3. Does it create an interesting decision rather than repetition?
4. Can it be represented through reusable systems and scenario data?
5. Does it remain usable on handheld controls and screens?
6. Can it scale to long sessions and large settlements?

Legacy parity is evidence about simulation behavior, not authority over the
physical game design.
