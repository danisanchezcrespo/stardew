extends SceneTree

const MachineType = preload("res://world/machines/physical_machine.gd")
const RouteType = preload("res://world/logistics/physical_route.gd")
const InventoryType = preload("res://player/player_inventory.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var registry := ItemRegistryType.new()
	registry.load_from_path("res://items/items.json")
	var source := InventoryType.new(registry, 4)
	var sink := InventoryType.new(registry, 100)
	var machine := MachineType.new("kiln", {"clay": 2}, {"mud_bricks": 1}, 0.05, registry, 50)
	machine.max_durability = 100000
	machine.durability = 100000
	var inbound := RouteType.new("in", "source", "kiln", 0.01)
	var outbound := RouteType.new("out", "kiln", "sink", 0.01)
	source.add("clay", source.capacity_for("clay"))
	for _tick in range(10000):
		inbound.process(0.01, source, machine)
		machine.process(0.01)
		outbound.process(0.01, machine.output_inventory, sink)
	_expect(sink.count("mud_bricks") > 0, "Long session should sustain end-to-end production.", failures)
	_expect(source.count("clay") + machine.input_inventory.count("clay") + sink.count("mud_bricks") * 2 <= 200, "Long session must not create resources from nothing.", failures)
	_expect(inbound.progress() >= 0.0 and inbound.progress() <= 1.0, "Route progress must stay bounded.", failures)
	if failures.is_empty():
		print("PASS: long session")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
