# Controls and interface contract

Status: initial cross-platform specification. Bindings and dimensions are
provisional until tested on keyboard, controller and touch.

## Input actions

Gameplay code consumes named actions, never hardware keys directly.

| Action | Keyboard/mouse | Controller | Touch intent |
| --- | --- | --- | --- |
| Move | WASD / arrows | Left stick / D-pad | Virtual stick |
| Interact/open | E | South face button | Context button |
| Pick up / place | Space | West face button | Context action |
| Craft selected recipe | Enter | South face button | Craft button |
| Use selected item | Left mouse / Space | West face button | Use button |
| Cancel / back | Escape / right mouse | East face button | Back button |
| Inventory | Tab / I | North face button | Inventory icon |
| Quick-slot previous/next | Wheel / Q-R | Bumpers | Tap slot / swipe bar |
| Rotate blueprint | R | Right bumper | Rotate button |
| Pause | Escape / P | Menu button | Pause icon |
| Strategic map | M | View button | Map icon |
| Quick save / load | K / L | Menu flow | Save/load buttons |
| Camera zoom | Mouse wheel | — | Pinch/buttons |
| Next villager | Tab | — | Community list |
| Move selected villager | Left click empty ground | — | Tap ground |
| Building details | Enter | South face button | Tap details |
| Toggle fullscreen | Alt+Enter / F11 | — | Display settings |

Bindings must be remappable. Prompts display the active device and update when
the last-used device changes.

## Input architecture

An input-intent layer converts hardware events into gameplay commands. Player,
world and UI systems must not check specific keys. This supports:

- Keyboard and mouse.
- Xbox, PlayStation and Switch-style controllers.
- Touch controls.
- Rebinding.
- Automated input tests.
- Future accessibility devices.

Movement uses a two-dimensional intent vector. Interaction, use, cancel and
menu actions are discrete intents. Placement uses character movement plus
rotate, confirm and cancel. The ghost stays immediately in front of the physical
character; pointer input confirms that same local position and never moves the
blueprint remotely.

Storage uses a two-column transfer layout. Left/right selects Player Inventory
or Crate Inventory, up/down selects a slot in that column, and Space transfers
the complete selected stack to the opposite side.

## Interaction feedback

At most one target is primary at a time.

The primary target displays:

- A high-contrast outline or ground marker.
- One verb-led prompt.
- Optional compact secondary status.

Examples:

- `Wood ×12` / `Space to pick up`, displayed above the resource
- `Storage crate` / `Space to place`, displayed above the placement ghost
- `Wood ×12` / `Space to place`, displayed above a construction blueprint
- `Ready to build` / `Hold Space to build`, displayed above a ready blueprint
- `E  Open brick kiln`
- `E  Add materials (18/25)`
- `Hold E  Repair`

If an action fails, feedback appears near the action and names the cause:
`Inventory full`, `Needs hammer`, `Output blocked`, or `Cannot reach port`.

## HUD layers

### Exploration HUD

Always visible but minimal:

- Quick bar.
- Selected item and stack count.
- Contextual interaction prompt.
- Current objective summary.
- Important alert indicator.

Population, global stock totals and production graphs are not permanently
displayed unless a scenario specifically requires them.

### Local panel

Opened by interacting with a building. It occupies part of the screen and keeps
the world visible. It contains:

- Entity name and state.
- Input/output inventories.
- Recipe and progress.
- Worker assignment.
- Blocking reason.
- Relevant local actions.

The simulation continues while this panel is open.

### Planning views

Map, route editor, technology, settlement overview and save/load are larger
views. They pause by default in single-player. They may inspect globally but may
only issue actions explicitly classified as planning actions; ordinary picking,
repairing and depositing remain local.

## Inventory interaction

The same operations must be available without drag-and-drop:

- Select stack.
- Move one.
- Move a configurable amount.
- Move maximum possible.
- Deposit all compatible.
- Sort.
- Assign to quick bar.

Mouse drag-and-drop may be offered as an additional shortcut. Controller uses
focus navigation and action buttons. Touch uses tap, hold and explicit quantity
controls rather than precision dragging as the only path.

## Placement interface

Placement mode shows:

- Blueprint ghost.
- Footprint cells.
- Facing/orientation.
- Interaction and logistics ports when relevant.
- Construction cost.
- Validity state and rejection reason.
- Confirm, rotate and cancel prompts.

The camera remains centered enough to keep the player visible. Placement cannot
occur outside local build range even if the cursor or touch point can reach it.

## Alerts

Alerts have severity and location:

- Informational: completed batch or objective update.
- Attention: low input, route delay or maintenance approaching.
- Critical: stopped essential production, starvation or cascading failure.

Alerts must be rate-limited, group repeated causes and navigate to their world
location. Color is never the sole severity signal.

## Accessibility baseline

- Remappable controls.
- Adjustable text/UI scale.
- High-contrast focus and placement states.
- Icon plus text for critical state.
- Reduced camera motion option.
- Optional hold/toggle behavior for repeated interaction.
- No essential distinction based only on red/green.
- Pause available without penalty.
- Subtitles or visual equivalents for gameplay-significant audio.

## UI implementation constraints

- Use Godot `Control` layout containers and anchors, not fixed screen positions.
- Respect handheld safe areas.
- Keep simulation state outside UI nodes.
- UI sends commands and observes state; it does not perform simulation logic.
- Every panel must be navigable through focus without a mouse.
- World interaction remains testable without rendering.
