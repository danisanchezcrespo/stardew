# Milestone 4: pickup and inventory

Status: in progress.

## Outcome

The player can approach physical resource stacks, identify one contextual target,
pick up as much as fits, and see the result in a limited slot inventory.

## Progress

- [x] Data-driven item definitions and stack limits.
- [x] Twelve-slot player inventory with transactional add/remove operations.
- [x] Physical world pickup stacks with stable IDs.
- [x] Deterministic range, facing, distance and ID target selection.
- [x] Context prompt and target highlight.
- [x] Partial pickup when inventory capacity is limited.
- [x] Inventory HUD readable during movement.
- [x] Automated inventory, targeting and pickup tests.
- [ ] Visual acceptance walkthrough.

## Acceptance walkthrough

The player walks to wood, clay and grain stacks, sees exactly one highlighted
target and verb-led prompt, presses the interaction action, and sees the stack
enter the inventory. A remainder stays in the world when the inventory cannot
accept the full amount.
