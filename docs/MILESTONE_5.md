# Milestone 5: inventory crafting

Status: in progress.

## Outcome

The player opens a crafting submenu, browses data-driven recipes, sees missing
ingredients, and converts inventory stacks into new items without loss or
duplication. At least one crafted item is marked as placeable for the next
milestone.

## Progress

- [x] Data-driven recipe definitions.
- [x] Ingredient and output-capacity validation.
- [x] Transactional crafting operation.
- [x] Keyboard and controller-navigable crafting submenu.
- [x] Recipe availability and ingredient feedback.
- [x] Crafted output appears in the player inventory HUD.
- [x] Placeable storage-crate item recipe.
- [x] Automated domain and scene integration tests.
- [ ] Visual acceptance walkthrough.

## Acceptance walkthrough

The player collects wood, opens crafting with `C`, selects Storage Crate, sees
the required wood, crafts it, and observes that wood was consumed and the crate
appeared in the inventory. An unavailable recipe explains what is missing and
does not alter inventory.
