# Milestone 16 — A living Nile settlement

This milestone turns the technical slice into the first long-form playable
campaign: 31 guided chapters and a closed settlement economy.

## Campaign and economy

- Five new industries: limestone quarry, copper mine, copper smelter, linen
  weaver, and papyrus workshop.
- Nine new resources and intermediates, including dressed stone, copper,
  linen, papyrus, and bronze tools.
- A multi-tier production chain culminating in the River Temple.
- Renewable flax and papyrus sources, authored paths, and two playable maps.

## People and logistics

- Six selectable villager appearances, editable names, hunger, energy, sleep,
  eating, work priority, and queued movement waypoints.
- Physical porter routes from crates, workshops, and any water tile.
- Logistics dashboard with live diagnostics, trip counters, pause/resume, and
  deletion; directional world arrows expose paused and blocked routes.

## Presentation and usability

- Alegreya Sans typography, framed panels, improved title screen, and complete
  pause/save/load/fullscreen menu.
- Autosave every 90 seconds and backward-compatible manual saves.
- Touch movement and action controls in mobile builds.
- Animated workshop smoke, broken-machine markers, and original feedback sounds.
- New pixel-art atlases for industries, items, and male villager animation.

## Verification

The headless suite covers the extended economy, campaign, imported assets,
paths, sources, UI actions, and all existing gameplay regressions on Godot 4.7.1.
