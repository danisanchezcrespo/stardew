# STARDew — Godot source

This directory contains the new Godot implementation. The Python project in
`../legacy_simcity` is reference material only and must not be modified as part
of the port.

Main structure:

- `simulation/`: rendering-independent simulation code.
- `scenarios/`: scenario data and assets.
- `tests/`: parity and regression tests.

Open `project.godot` with Godot 4.x.

New games begin in the Museum of the Time Traveler. Its first portal can be
bound to any era; later portals awaken after 3, 8, and 15 artifacts have been
physically recovered from campaign milestones and exhibited in the archive.
Each era keeps its own settlement save and ordinary inventory. Only temporal
artifacts cross a portal, and the 20-piece museum collection reveals the
traveler's backstory in five order-independent chapters.

The Ancient Egypt campaign contains 31 chapters and a complete manual-to-
automated production arc. Use `Space` for contextual interaction, `C` for
crafting, `T` for the technology tree, `M` for the era collection, `Tab` for
villagers, `G` for logistics, `Esc` for pause, and `F11`
or `Alt+Enter` for fullscreen. Progress autosaves every 90 seconds; manual
save/load are available from the pause menu and on `K`/`L`.

Each eight-day season advances through a scenario-specific calendar. Donating
one of each collection item awards knowledge used to unlock connected
technology nodes. Completed buildings can be upgraded twice; workshops gain
production speed and durability, stores gain slots, and homes gain a resident.
