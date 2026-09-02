PROJECT: STARDew

What this project is



This project is the evolution of an existing Python prototype called SimCity.



The Python project is included in:



/legacy\_simcity



It is a REFERENCE IMPLEMENTATION.



Do not extend the Python game.

Do not maintain compatibility with its UI.

Do not use Python in the final product.



The goal is to port its simulation systems and data-driven architecture to Godot, then evolve it into a tile-based 2D game controlled through a physical player character.



Product vision



The final game is a 2D top-down pixel-art builder/simulation game for mobile and Nintendo Switch.



The player controls a physical character moving in four directions through a tile-based world.



Unlike a traditional god-game, the player cannot interact with the world globally.



The player must physically:



move through the world

collect resources

carry resources

craft items

place buildings

deliver materials

interact with machines

repair systems

manage the settlement from inside the settlement



The game is designed for extremely long continuous play sessions, including flights lasting 10–15 hours.



There must always be something useful to do.



The game must work fully offline.



Core design philosophy



The game combines:



the physical world interaction and readability of Stardew Valley

the systemic production and optimization depth of Factorio

the instability and feedback systems of classic SimCity



However, the core game is closer to Factorio than Stardew Valley.



The player builds increasingly complex systems.



Growth creates complexity.



Complexity creates fragility.



Fragility creates new problems.



The player solves those problems and expands again.



Core loop:



BUILD

→ PRODUCE

→ AUTOMATE

→ OPTIMIZE

→ EXPAND

→ DESTABILIZE

→ REPAIR / ADAPT

→ EXPAND AGAIN



Progress must not be purely monotonic.



The player's total capability should increase over time, but systems should become increasingly difficult to keep stable.



Failures should normally create gameplay rather than game-over states.



Multiple scenarios



The game is not one specific builder.



It is a container for multiple builder scenarios.



Examples:



Mars colony

Farm

Ancient Egypt

Aztec city

Wild West town

Hell

Space station



Each scenario has different:



graphics

tiles

resources

entities

production chains

environmental rules

failure systems

progression

objectives



The engine must therefore be highly data-driven.



A new scenario should ideally be created primarily through data files and assets rather than new hardcoded gameplay code.



LEGACY SIMCITY



The existing Python project already implements many simulation systems.



Study the entire /legacy\_simcity project before implementing equivalents.



Important existing concepts include:



Entity definitions

Entity instances

inventories

construction costs

construction progress

production recipes

processing time

resource capacities

workers

worker assignment

worker efficiency

global resource modifiers

production priorities

transport edges

transport capacity

transport speed

resource packets in transit

population

food consumption

population growth / decline

building states

save/load

data-driven JSON definitions



These concepts should be preserved unless there is a clear architectural reason to change them.



Do not simplify working simulation behavior without documenting why.



DATA MODEL



The existing JSON data model is an important part of the design.



For example, an entity can currently define:



id

label

construction\_cost

initial\_amounts

max\_amounts

recipe\_inputs

recipe\_outputs

source\_rate\_per\_sec

process\_time\_sec

shared\_resource\_modifiers

workers\_required

worker\_priority

min\_worker\_efficiency



This philosophy should continue.



The Godot engine should not contain special-case logic such as:



"If entity is BRICK\_KILN, make bricks."



Instead:



"The entity consumes these resources, waits this processing time, then produces these resources."



Scenario-specific behavior should be expressed through reusable systems and data whenever possible.



GODOT TARGET



Create the new implementation in Godot.



The Python runtime must NOT be required by the final game.



Target architecture:



Simulation



independent from rendering whenever practical



World



tile/grid based



Player



physical 2D character

four-direction movement

collision

inventory

local interaction



Entities



physically placed on grid

may occupy multiple cells

may contain inventories

may transform resources

may require workers

may degrade or fail

may participate in logistics networks



Persistence



save complete simulation state

deterministic/reproducible where practical



Platforms



desktop during development

mobile

Nintendo Switch later



Offline-first.



MIGRATION STRATEGY



Do NOT attempt to rewrite the entire game in one operation.



Port the legacy simulator incrementally.



Phase 1 — Simulation parity



Create a headless Godot simulation capable of loading the legacy JSON entity definitions.



Port the core simulation behavior.



Use the Ancient Egypt scenario as the reference case.



The goal is to prove that the Godot simulation behaves equivalently to the Python simulation.



Graphics are irrelevant at this stage.



Phase 2 — Grid world



Replace free world coordinates with grid-based placement.



Entities occupy one or more grid cells.



Introduce collision and occupancy.



Phase 3 — Player agent



Add a CharacterBody2D player.



Four-direction movement.



The player must physically approach objects to interact with them.



Introduce player inventory.



Phase 4 — Physical interaction



Convert god-game actions into player actions.



Examples:



OLD:



click building in palette

→ click map

→ building created



NEW:



craft/build blueprint

→ walk to location

→ place blueprint

→ supply construction materials

→ building becomes operational



Phase 5 — Logistics



Adapt the legacy edge/transport system to the physical grid world.



Do not assume the old edge implementation must remain visually identical.



Possible implementations may include:



workers

carts

roads

belts

pipes

cables

routes



The simulation concepts should remain generic.



Phase 6 — Entropy and instability



Introduce systems that prevent purely monotonic expansion.



Examples:



degradation

maintenance

resource depletion

overload

cascading failures

environmental events

logistics congestion

population pressure



These systems should create optimization problems rather than arbitrary punishment.



DEVELOPMENT RULES

Treat /legacy\_simcity as reference material.

Never modify legacy files unless specifically requested.

Implement new production code in the Godot project.

Prefer generic reusable systems over scenario-specific code.

Keep simulation logic separate from rendering/UI whenever reasonable.

Keep game balance in data files, not GDScript constants.

Before replacing a legacy behavior, understand how the Python version works.

Port incrementally and test each subsystem.

Avoid premature visual polish.

The first priority is a robust simulation engine.

FIRST MILESTONE



The first milestone is:



Load the existing Ancient Egypt entity JSON in Godot and reproduce the core legacy simulation without the legacy UI.



At minimum support:



entity definitions

entity instances

inventories

construction

recipes

processing

workers

production

resource transport

global state

save/load



Create tests or debug tooling that allow behavior to be compared against the legacy Python implementation.



Do not implement the final pixel-art UI until this milestone is working.

