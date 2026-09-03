# Milestone 3: physical player

Status: complete (validated in Godot on 2026-09-03).

## Outcome

The main scene is experienced through a physical top-down character rather than
an omnipresent placement cursor. Walking, facing, collision and camera behavior
form a stable base for later pickup and contextual interaction.

## Progress

- [x] Continuous normalized movement through named input actions.
- [x] Four-direction facing independent from movement animation.
- [x] Character collision with terrain and world boundaries.
- [x] Following camera constrained to the authored world.
- [x] Keyboard and controller-compatible movement.
- [x] Placeholder presentation with readable position and facing HUD.
- [x] Automated movement and collision checks.
- [x] Visual acceptance walkthrough.

## Acceptance walkthrough

The player can move with keyboard or controller in all directions, cannot walk
through water or leave the map, retains the last facing direction when stopped,
and remains framed by a camera that does not reveal space outside the world.

## Explicit non-goals

- Picking up items or inventory.
- Contextual interaction targeting.
- Crafting.
- Player-driven building placement.
- Final character art or animation.

Those systems build on this movement contract in subsequent milestones.
