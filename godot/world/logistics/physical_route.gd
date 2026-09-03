class_name PhysicalRoute
extends RefCounted

var route_id: String
var source_id: String
var destination_id: String
var villager_id := ""
var item_id := ""
var travel_seconds: float
var progress_seconds := 0.0
var trips_completed := 0
var last_item_id := ""

func _init(id: String, from_id: String, to_id: String, duration: float = 2.0, worker_id: String = "", resource_id: String = "") -> void:
	route_id = id
	source_id = from_id
	destination_id = to_id
	travel_seconds = maxf(duration, 0.1)
	villager_id = worker_id
	item_id = resource_id

func process(delta: float, source_inventory: Variant, destination: Variant) -> int:
	progress_seconds += maxf(delta, 0.0)
	if progress_seconds < travel_seconds:
		return 0
	progress_seconds = fmod(progress_seconds, travel_seconds)
	for slot: Dictionary in source_inventory.slots:
		if slot.is_empty():
			continue
		var accepted := 0
		if destination.has_method("add_input"):
			accepted = destination.add_input(slot.item_id, 1)
		elif destination.has_method("add"):
			accepted = destination.add(slot.item_id, 1)
		if accepted > 0:
			source_inventory.remove(slot.item_id, accepted)
			last_item_id = slot.item_id
			trips_completed += 1
			return accepted
	return 0

func progress() -> float:
	return clampf(progress_seconds / travel_seconds, 0.0, 1.0)
