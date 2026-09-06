# Milestone: Diegetic Progression

Progression is now reached through places and objects in the world rather than unexplained global shortcuts.

## Rest

The global `N` sleep action has been removed. The player builds and approaches the Traveler's Cottage, opens it with the normal interaction action, and chooses **Sleep until 07:00**. Sleeping advances the day, returns the player home, restores the daily rhythm, and wakes sleeping villagers together.

## Research

The global `T` technology action has been removed. Each playable era now has a physical research hub:

- Prehistory: Story Circle
- Ancient Egypt: House of Wisdom
- Medieval: University
- Mars: Research Laboratory

Their plans belong to each era's foundational technology, so the player can always establish the hub through ordinary crafting and blueprint construction. Opening the completed hub exposes the progressive research tree. Collection discoveries provide Knowledge; prerequisites and Knowledge costs unlock successive layers and their recipes.

## Workshop mastery

Every physical machine with a recipe catalogue owns its own mastery:

- Mastery 1, 0 completed batches: first two recipes.
- Mastery 2, 5 completed batches: first four recipes.
- Mastery 3, 12 completed batches: first six recipes.
- Mastery 4, 24 completed batches: complete catalogue.

Locked products appear explicitly in the machine panel with their required mastery. Catalogue workshops level automatically through production and no longer expose a material-payment upgrade button. Their mastery also improves production speed by 25% per level and appears as the building's world badge.

Mastery derives from the already-persisted completed batch count, so existing saves remain compatible.

## UX rule

Keyboard shortcuts remain for ordinary interface navigation (crafting, journal, calendar, menu), but no key directly advances time or opens progression divorced from its world context.

Automated coverage lives in `test_diegetic_ux.gd`, `test_medieval_customization.gd`, and `test_four_era_content.gd`.
