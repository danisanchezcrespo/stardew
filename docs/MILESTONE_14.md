# Milestone 14: physical-world save and recovery

Status: implementation complete; visual walkthrough pending.

## Outcome

K writes a versioned physical-world save and L restores it into a fresh
session. The snapshot includes player, world resources, inventory, buildings,
construction, storage, production, wear, routes and campaign completion.

## Progress

- [x] Versioned JSON physical-world snapshot.
- [x] Player, inventory and pickup persistence.
- [x] Stable placed-building and container restoration.
- [x] Construction, machine, maintenance and route state support.
- [x] K/L controls with explicit feedback (avoids Godot editor F5/F6 shortcuts).
- [x] Atomic temporary-file write with last-save rollback protection.
- [x] Automated file round-trip into a fresh game instance.
- [x] Safe in-session scene reload before restoring an occupied world.
- [ ] Visual acceptance walkthrough.
