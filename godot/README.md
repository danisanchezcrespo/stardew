# STARDew — Godot source

This directory contains the new Godot implementation. The Python project in
`../legacy_simcity` is reference material only and must not be modified as part
of the port.

Main structure:

- `simulation/`: rendering-independent simulation code.
- `scenarios/`: scenario data and assets.
- `tests/`: parity and regression tests.

Open `project.godot` with Godot 4.x.

The Ancient Egypt campaign contains 31 chapters and a complete manual-to-
automated production arc. Use `Space` for contextual interaction, `C` for
crafting, `Tab` for villagers, `G` for logistics, `Esc` for pause, and `F11`
or `Alt+Enter` for fullscreen. Progress autosaves every 90 seconds; manual
save/load are available from the pause menu and on `K`/`L`.
