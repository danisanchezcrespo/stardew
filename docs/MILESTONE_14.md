# Milestone 14: physical-world save and recovery

Status: implementation complete; visual walkthrough pending.

## Outcome

F5 writes a versioned physical-world save and F9 restores it into a fresh
session. The snapshot includes player, world resources, inventory, buildings,
construction, storage, production, wear, routes and campaign completion.

## Progress

- [x] Versioned JSON physical-world snapshot.
- [x] Player, inventory and pickup persistence.
- [x] Stable placed-building and container restoration.
- [x] Construction, machine, maintenance and route state support.
- [x] F5/F9 controls with explicit feedback.
- [x] Automated file round-trip into a fresh game instance.
- [x] Safe in-session scene reload before restoring an occupied world.
- [ ] Visual acceptance walkthrough.
