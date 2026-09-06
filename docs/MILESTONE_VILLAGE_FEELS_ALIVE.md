# Milestone: The Village Feels Alive

This milestone turns medieval town layout into a social optimization problem and makes productive buildings visibly active.

## Villager happiness

Every villager has a stable personality derived from their identity. Changing their name or clothing does not reroll it. The current personalities deliberately conflict:

- Garden Souls enjoy flowers, nature, and water, but dislike noisy industry.
- Proud Artisans want statues, markets, and workshops, but dislike isolation.
- Old Traditions villagers enjoy monuments, the keep, and quiet, but dislike flowers and markets.
- Village Socialites want markets, neighbors, and flowers, but dislike isolation and excessive quiet.
- Woodland Hearts enjoy nature, water, and quiet, but dislike industry, markets, and statues.
- Practical Makers enjoy industry, the forge, and markets, but dislike flowers and water.

Happiness also responds to hunger, energy, housing, and whether a villager has work they find fulfilling. Nearby town features are evaluated within eight world cells of the villager's home.

The villager panel shows a color-coded 0-100 happiness bar, personality, likes, hates, and the strongest positive and negative causes. The top HUD shows village average and lowest happiness; the Journal adds average, lowest, and cohesion.

Happiness has a gameplay consequence: assigned workers range from 65% to 115% of their normal contribution. A beautiful town that makes one resident happy can irritate their neighbor, so there is no universally perfect layout.

Happiness is included in physical save data and is recalculated as needs and town layout change.

## Ambient delight

Active medieval buildings now advertise their work in the world:

- windmill blades rotate;
- the forge burns, throws sparks, and shows a tiny hammering worker;
- the sculptor workshop shows a worker striking stone and producing dust;
- gardens sprinkle water;
- apiaries orbit with bees;
- bakeries and kitchens glow warmly;
- fountains sparkle, flowers sway, and chickens peck around their coop.

These effects are procedural overlays on the existing authored sprites, so they preserve the established perspective and scale while making the town readable at a glance.

## Verification

- `test_villager_happiness.gd` covers incompatible preferences, hunger penalties, and stable personalities.
- `test_physical_save.gd` covers happiness persistence.
- The complete Godot test suite remains the regression gate.
- `tools/capture_scenario.gd ... happiness` produces a visual QA view of the populated town and villager panel.
