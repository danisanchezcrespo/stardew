# Simulation

Rendering-independent simulation systems belong here.

Current layers:

- `definitions/`: immutable scenario definitions loaded from JSON.
- `state/`: mutable node, edge, packet, and settlement state.
- `systems/`: stateless or narrowly scoped simulation operations.

Implemented systems currently cover inventory, construction, graph mutation,
continuous sources, timed production batches, output capacities, staffing
efficiency, production of globally pooled transport resources, settlement food
consumption, population change, attractiveness, priority-based staffing, and
capacity-reserved packet transport with one-way or ping-pong movement.

`simulation_engine.gd` is the rendering-independent facade. Its explicit
`step(dt)` method composes all systems in the audited legacy order and is the
only tick entry point that gameplay code should use.
