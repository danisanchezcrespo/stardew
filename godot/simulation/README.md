# Simulation

Rendering-independent simulation systems belong here.

Current layers:

- `definitions/`: immutable scenario definitions loaded from JSON.
- `state/`: mutable node, edge, packet, and settlement state.
- `systems/`: stateless or narrowly scoped simulation operations.

Implemented systems currently cover inventory, construction, graph mutation,
continuous sources, timed production batches, output capacities, staffing
efficiency, production of globally pooled transport resources, settlement food
consumption, population change, attractiveness, and priority-based staffing.
