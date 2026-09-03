extends SceneTree

const MachineType = preload("res://world/machines/physical_machine.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var registry := ItemRegistryType.new()
	registry.load_from_path("res://items/items.json")
	var machine := MachineType.new("kiln", {"clay": 1}, {"mud_bricks": 1}, 0.1, registry)
	for _batch in range(3):
		machine.add_input("clay", 1)
		machine.process(0.01)
		machine.process(0.1)
	_expect(machine.broken, "Machine should break after its durability is exhausted.", failures)
	var output_before: int = machine.output_inventory.count("mud_bricks")
	machine.add_input("clay", 1)
	machine.process(1.0)
	_expect(machine.output_inventory.count("mud_bricks") == output_before, "Broken machine must stop safely.", failures)
	_expect(machine.repair("clay", 2) == 0 and machine.broken, "Incorrect repair resource should be rejected.", failures)
	_expect(machine.repair("wood", 2) == 2 and not machine.broken, "Two wood should restore a broken machine.", failures)
	machine.process(0.01)
	machine.process(0.1)
	_expect(machine.output_inventory.count("mud_bricks") == output_before + 1, "Repaired machine should resume queued work.", failures)
	if failures.is_empty():
		print("PASS: machine maintenance")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
