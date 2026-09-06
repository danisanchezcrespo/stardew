# First Living Year

This milestone turns the medieval valley into a repeating, authored calendar rather than a finite construction sequence.

## Calendar

- A week has 7 named days. Saturday and Sunday are market days.
- A season has 4 weeks (28 days).
- A year has Spring, Summer, Autumn, and Winter (112 days).
- Sleeping advances to 07:00 the following day. Press `B` to open the Living Year calendar.
- Completing the Keep unlocks optional weekly ambitions and one seasonal great project at a time.

## First-year novelty

The first year introduces the henwife and chicken coops, an herbalist and herb gardens, the northern ruin cache, beekeeping and apiaries, a summer storm choice, the Harvest Feast, winter snow, an astronomer and her tower, an eclipse, and a Year Two visitor. These beats unlock recipes, resources, map discoveries, decisions, and persistent memories.

Great projects permanently alter the map and reward a chosen settlement identity. Weekly ambitions are optional short goals. The Autumn 28 feast scores stored food, community, and beauty. Winter 28 records a year review; the next morning begins Year Two without resetting the settlement.

## Seasonal rules

- Spring alternates clear days, mist, and rain.
- Summer has frequent rain and an authored major storm.
- Autumn brings mist, rain, higher harvest value, and the feast.
- Winter covers the map in snow and slows outdoor production.
- Weekends add market decoration, social time, and better sale prices.

## Authoring

All scheduled content is configured in `res://world/progression/medieval_timeline.json`. An event can specify calendar conditions, dialogue, recipe unlocks, granted items, spawned pickups, weather, memories, and player choices. Weekly ambitions define a metric, target, and reward. Seasonal projects define their season, material cost, reward, and lasting world change.

The `TimelineDirector` owns evaluation and persistence. Its complete snapshot is stored in normal save games, including fired events, choices, unlocked recipes, active progress, projects, memories, festival score, and year history. New authored events therefore do not require changes to the save format or the main gameplay loop.

## New production chains

- Chicken Coop: wheat and water sustain chickens; cared-for chickens lay eggs and can eventually be processed for meat.
- Herb Garden: water and wild herbs produce medicinal herbs.
- Village Apiary: wild herbs produce honey.
- Festival Platter: loaf, egg, and honey create a high-value feast contribution.
- Astronomer's Tower: ruin fragments produce star charts.

The new products are tradeable and can be donated to the Royal Cabinet.

## QA

Run the automated suite with every `res://tests/test_*.gd` script. `test_timeline_director.gd` covers scheduling, choices, unlocks, projects, ambitions, and persistence. `test_timeline_visual_assets.gd` guards the transparency and color of the new building artwork.
