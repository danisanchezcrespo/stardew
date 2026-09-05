# Villagers, needs, and physical work

The physical game models a small persistent community rather than an abstract
worker total. The player is the founder; each completed dwelling creates the
number of residents specified by its bed capacity (currently two).

## Selecting and naming

- Approach a villager and press `Space`, or press `Tab` to cycle through villagers.
- The characteristics panel shows home, current state, hunger, energy, task,
  and carried item.
- Edit the name field and press `Enter` (or click elsewhere) to rename them.
- Choose one of six character appearances: two body sprites and three clothing palettes.
- Choose relaxed, normal, or urgent work priority.
- Names, appearance, priority, needs, position, home, queued tasks, and cargo are saved.

## Transport orders

1. Select a villager and choose **Assign transport**.
2. Click a completed crate or machine as the source.
3. Choose the transported resource in the characteristics panel.
4. Click a compatible crate or machine as the destination.

The villager walks to the source, carries up to three units, walks to the
destination, delivers, and repeats. The order waits visibly if the source is
empty or the destination cannot receive more. Routes never transfer resources
without their assigned villager.

Press `G` to open Settlement Logistics. Every route reports its worker,
resource, endpoints, completed trips, and live state. Routes can be paused,
resumed, or deleted. Yellow arrows indicate active routes, grey indicates a
paused route, and red indicates waiting or blockage. Water tiles can serve as
infinite route sources.

Click empty ground to send the selected villager there. Shift-click adds a
waypoint instead of replacing the active move order.

## Work orders

Choose **Assign work**, then click a kiln or construction site. A construction
worker contributes work after all materials have been delivered. A kiln only
runs while an assigned villager is physically at the workplace.

## Needs and daily routine

- Hunger falls faster while active. Below 30%, villagers move more slowly and
  autonomously seek a food ration in a storage crate. At zero food they stop.
- Energy falls while active. At night or when exhausted, villagers return to
  their assigned home, sleep, and resume the previous task the next morning.
- Food is physical: eating removes one `food_ration` from a real crate.

## Building details

Approach a building and press `Space`. Workshops expose health, worker, progress,
input, and accumulated output. Homes expose beds, residents, and resident
needs. Construction sites expose delivered materials and work progress.
