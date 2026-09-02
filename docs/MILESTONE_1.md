# Milestone 1 — simulation parity

Status: complete as of 2026-09-03.

## Acceptance criteria

The Godot project can load the Ancient Egypt entity definitions and reproduce
the core Python simulation without its UI or runtime. It supports:

- Entity definitions and runtime instances.
- Local inventories and configured capacities.
- Construction costs, deliveries, progress and promotion.
- Continuous sources and timed recipe batches.
- Population, food consumption, attractiveness and worker allocation.
- Directed transport, trip capacity, reservations, packets and empty returns.
- Globally pooled transport resources and edge spending/refunds.
- Structural entity unlocking.
- Version 1 save/load, including active processes and transport in flight.
- Deterministic explicit stepping independent of rendering.

## Evidence

The headless Godot suites test each subsystem directly. The cross-engine runner
executes the same JSON command scenarios against Python and Godot, then compares
complete normalized state with an absolute numeric tolerance of `1e-9`.

The parity matrix includes the two bundled Ancient Egypt saves plus focused
fixtures for production, construction, logistics, deletion, population,
staffing, progression, persistence continuation and synthetic edge cases. See
`docs/PARITY_MATRIX.md` for the current list.

## Deliberately preserved legacy behavior

Parity currently preserves behaviors that may be revised after this milestone:

- Population can grow from zero without food on its first tick.
- Minimum staffing efficiency can permit production with no assigned workers.
- Transport resources enter a global pool rather than a node inventory.
- Unfinished placed entities count toward structural unlocks.
- Deleting an occupied edge destroys its cargo but refunds its transporter.
- A multi-output source can discard overflow from a full output while another
  output still has capacity.
- Construction requires delivered materials but no time or labor.

Any future correction must be recorded as an intentional divergence and paired
with updated tests.

## Out of scope

Tk UI behavior, freeform legacy presentation, camera state and Python runtime
compatibility are not part of the Godot product. Grid occupancy, the physical
player, local interaction and final rendering begin in milestone 2 and later.
