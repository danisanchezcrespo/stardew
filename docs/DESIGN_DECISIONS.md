# Design decisions and open questions

This log separates decisions required for the next implementation milestone from
questions that can safely wait for playtesting.

## Adopted for the first vertical slice

| Topic | Initial decision | Revisit trigger |
| --- | --- | --- |
| World grid | 32×32 logical pixels per tile. | Art readability or handheld tests fail. |
| Movement | Continuous four-direction character movement. | Navigation feels imprecise on touch. |
| Base speed | 4 tiles/second. | Traversal is tedious or spaces lose meaning. |
| Interaction range | 1.25 tiles with facing preference. | Target selection is frustrating. |
| Placement range | 4 tiles from player. | Building placement feels cramped or remote. |
| Inventory | 12 slots, stack limits, no weight. | Carrying has no strategic effect. |
| Quick bar | 8 references into the main inventory. | Handheld layout becomes crowded. |
| Simulation | Fixed explicit 10 Hz tick. | Profiling requires another rate. |
| Pause | Full planning screens pause; local panels do not. | Playtests show unwanted pressure. |
| Construction | Materials plus physical work. | Repetition outweighs spatial value. |
| Logistics | Visible porter is first automation. | Agent counts or pathfinding do not scale. |
| Population | Aggregated population, bounded visible workers. | Individual schedules become core fun. |
| Combat | Excluded from first vertical slice. | Scenario vision later requires it. |
| Stamina | Excluded from first vertical slice. | Manual work lacks meaningful tradeoffs. |
| Day/night | Excluded from first vertical slice. | Time structure becomes necessary. |

## Must be validated during milestones 2–4

- Whether 32-pixel tiles provide enough detail for ports and interaction points.
- Whether continuous movement around multicell buildings feels clear.
- Whether one contextual target is sufficient in dense production areas.
- Whether local placement range works with large building footprints.
- Whether 12 slots create decisions without excessive shuttle trips.
- Whether local panels should slow time as an accessibility option.
- Whether dropped stacks need merging and decay rules.

## Can wait until logistics and entropy

- Exact ratio between aggregate and visible workers.
- Schedules, shifts and sleeping.
- Road bonuses and terrain movement costs.
- Vehicle ownership versus route ownership.
- Resource depletion model.
- Maintenance interval and warning duration.
- Whether repairs consume time, parts, a tool, or all three.
- Rules for cascading failures and emergency recovery.

## Explicitly unresolved long-term questions

- Whether scenarios share a metaprogression layer.
- Whether maps are authored, generated or both.
- Whether the final game has a day/night calendar.
- Whether any scenario includes combat.
- Whether the player character has cosmetic or mechanical customization.
- How local multiplayer or online features would affect deterministic simulation;
  neither is currently planned.
