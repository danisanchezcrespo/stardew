# Milestone 7: physical storage transfer

Status: in progress.

## Outcome

A placed Storage Crate is a contextual world target with its own limited
inventory. The player can physically carry item stacks to it, deposit them and
withdraw them later through a controller-friendly local panel.

## Progress

- [x] Data-defined storage slot capacity.
- [x] Placed-object interaction point and target highlighting.
- [x] Local storage panel with separate player and crate inventories.
- [x] Transactional deposit and withdrawal with partial-capacity handling.
- [x] Movement disabled while the local panel is open.
- [x] Keyboard and controller transfer controls.
- [x] Multiple crates keep independent contents.
- [x] Automated end-to-end storage interaction tests.
- [ ] Visual acceptance walkthrough.

## Acceptance walkthrough

The player places a crate, approaches its interaction side, presses `E`, sees
both inventories, deposits the selected player stack, closes the panel, reopens
it, and withdraws the stored stack. Counts remain conserved throughout.
