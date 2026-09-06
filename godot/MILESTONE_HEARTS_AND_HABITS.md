# Hearts and Habits - Medieval vertical slice

This milestone turns the Medieval valley from a production sequence into a repeatable cozy-life loop. It deliberately remains confined to Medieval so the design can be tested before its generic pieces are adapted to other eras.

## Player loop

Open the Valley Journal with `J`. The bottom row exposes the optional daily activities: request, feast, merchant, conversation, gift, sale, ruins, and improvement. `N` ends the day. None of these is required to continue the construction campaign.

## The fourteen areas

1. **Relationships:** Alys, Edwin, Mabel, and Hugh have rotating dialogue, individual tastes, friendship points, hearts, and higher-bond revelations.
2. **Schedules:** villagers describe and physically follow breakfast, work, social, evening, rain, and sleeping routines when they have no player-assigned job.
3. **Sleeping ritual:** sleeping restores the player's daily energy, advances weather, requests, gifts, exploration attempts, story, and autosaves at the morning summary.
4. **Exploration:** the northern ruins have limited daily searches, energy cost, persistent depth, common finds, rare fragments, and a favorable weather/event modifier.
5. **Gift economy:** select an inventory item and give it from a villager panel or the Journal. Each person accepts one per day and reacts to loved, liked, or ordinary gifts.
6. **Desirable merchant stock:** early visits sell decorations; later cycles include a ruin map, permanent energy satchel, and cottage tapestry.
7. **Tool progression:** foraging, crafting, and exploration tools have four levels. Improvements consume coins and iron tools and reduce action energy costs or increase exploration.
8. **Customization:** placeable lanterns, benches, and flower beds build Beauty; the personal cottage has comfort levels and a persistent interior style.
9. **Daily randomness:** a deterministic save-safe daily condition changes sale prices, travel, exploration, gifts, or provides a calm day.
10. **Economy:** surplus materials and produce can be sold for coins; market-day demand raises values and coins feed upgrades, home, and merchant purchases.
11. **Skills:** foraging, crafting, exploration, and community actions earn persistent XP and visible levels.
12. **Atmosphere:** the existing day/night tint and weather now influence schedules, exploration, gifting, and the economy instead of being cosmetic only.
13. **Feedback:** actions retain audio feedback and now produce explicit contextual results, relationship reactions, heart changes, skill levels, and morning summaries.
14. **A place of your own:** the Traveler's cottage progresses through three comfort levels, consumes village resources, raises Beauty, and can gain a merchant-sold style.

## Persistence and compatibility

All new state lives under the existing `living` save section. Missing fields use safe defaults, so older Medieval saves remain loadable. Villager schedule state is also persisted. Relationship logic supports player-renamed villagers with generic dialogue and tastes.

