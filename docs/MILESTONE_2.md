# Milestone 2: physical world grid

Status: in progress.

## Progress

- [x] Coordinate, direction and footprint value types.
- [x] Pure footprint and port rotation functions.
- [x] Spatial definition schema and validation.
- [x] Terrain and occupancy grid with placement queries.
- [x] Placement/removal commands and stable entity IDs.
- [ ] Save/load extension.
- [ ] Debug scene and overlays.
- [ ] Full automated regression and acceptance walkthrough.

## Outcome

The project can represent, query, save and visualize a physical tile world in
which scenario-defined entities occupy footprints and expose interaction and
logistics points. This milestone establishes spatial truth; it does not yet add
the controllable player.

## Scope

### World coordinates

- Introduce explicit grid-cell and world-position conversion helpers.
- Keep simulation coordinates independent of the 32-pixel presentation scale.
- Define one origin and rotation convention for every footprint.
- Support rectangular and irregular footprint masks.

### Entity spatial definitions

Extend data definitions with optional spatial metadata:

- Footprint cells relative to an origin.
- Allowed quarter-turn rotations.
- Terrain requirements and exclusions.
- Collision cells.
- Named interaction points.
- Named input, output and service ports.

Definitions without spatial metadata must continue to load so existing parity
tests remain valid.

### Occupancy and placement

Add a world-grid service that owns:

- Terrain classification per cell.
- Entity occupancy per cell.
- Stable entity-to-cells lookup.
- Atomic reserve, place, move and remove operations.
- Placement queries that do not mutate state.

A placement query returns a structured result, including transformed footprint,
validity and stable reason codes such as:

- `OUT_OF_BOUNDS`
- `OCCUPIED`
- `INVALID_TERRAIN`
- `BLOCKS_REQUIRED_ACCESS`
- `ROTATION_NOT_ALLOWED`

Player range is not part of the grid service. It will be a rule applied by the
later construction interaction system.

### Persistence

- Save terrain identity, placed entity identity, origin and rotation.
- Reconstruct occupancy from authoritative placed entities on load.
- Reject or report corrupt overlaps rather than silently overwriting them.
- Preserve deterministic entity ordering and stable IDs.
- Continue loading the current simulation-only save format.

### Debug presentation

Create a temporary Godot debug scene that can:

- Draw the logical grid and a small authored terrain patch.
- Display valid and invalid transformed footprints.
- Show occupied cells and named ports.
- Place, rotate and remove sample entities through debug controls.
- Surface the first placement rejection reason.

This scene is a development instrument, not final player UI or art.

## Implementation order

1. Coordinate, direction and footprint value types.
2. Spatial definition schema and validation.
3. Pure footprint rotation and transformation functions.
4. Terrain and occupancy grid with placement queries.
5. Placement/removal commands and stable entity IDs.
6. Save/load extension.
7. Debug scene and overlays.
8. Automated regression and headless tests.

## Required automated cases

- World-to-cell and cell-to-world conversions agree at boundaries.
- Every supported footprint rotation produces the expected cells and ports.
- An irregular footprint does not occupy holes in its mask.
- Overlap, bounds, terrain and forbidden rotation return the correct reason.
- A rejected placement leaves all state unchanged.
- Removal frees exactly the cells owned by that entity.
- Saving and loading preserves origins, rotations, IDs and occupancy.
- A corrupt overlapping save is rejected deterministically.
- Existing simulation, savegame and cross-engine parity suites still pass.

## Acceptance walkthrough

In the debug scene, a developer can select sample one-cell, rectangular and
irregular entities; rotate their previews; see footprint and port overlays;
place them only on valid cells; receive a readable rejection reason; remove a
placed entity; save; reload; and observe the identical grid state.

The milestone is complete only when this walkthrough works with keyboard and
controller intents and all required tests pass headlessly.

## Explicit non-goals

- Player movement, animation or collision.
- Final construction costs or work progress.
- Inventory transfer.
- Pathfinding and porter agents.
- Final terrain art, building art or production UI.
- Touch-specific placement controls beyond preserving the input-intent boundary.

These belong to later milestones and must consume the spatial contracts created
here rather than duplicate them.
