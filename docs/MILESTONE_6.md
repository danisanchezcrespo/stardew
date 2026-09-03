# Milestone 6: place crafted objects

Status: in progress.

## Outcome

The player selects a crafted placeable item from the quick bar, previews its
footprint near the character, rotates it, and places it into the persistent
physical world. Inventory is consumed only after a valid placement succeeds.

## Progress

- [x] Data-driven placeable object catalog.
- [x] Eight quick-slot selection actions and visible selected slot.
- [x] Local placement mode with movement disabled.
- [x] Grid preview, rotation and rejection feedback.
- [x] Build-range, terrain, overlap and player-cell validation.
- [x] Atomic world placement and inventory consumption.
- [x] Placed-object collision and world rendering.
- [x] Keyboard, mouse and controller controls.
- [x] Automated end-to-end craft-to-place tests.
- [ ] Visual acceptance walkthrough.

## Acceptance walkthrough

The player collects wood, crafts a Storage Crate, selects its inventory slot,
enters placement mode, moves the preview, sees invalid cells in red, confirms a
valid cell, and can no longer walk through the placed crate. Exactly one crate
is removed from inventory.
