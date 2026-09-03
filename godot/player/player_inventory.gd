class_name PlayerInventory
extends RefCounted

var registry: Variant
var slot_count: int
var slots: Array[Dictionary] = []


func _init(item_registry: Variant, inventory_slot_count: int = 12) -> void:
	assert(inventory_slot_count > 0, "Inventory must contain at least one slot.")
	registry = item_registry
	slot_count = inventory_slot_count
	for _index in range(slot_count):
		slots.append({})


func count(item_id: String) -> int:
	var total := 0
	for slot: Dictionary in slots:
		if slot.get("item_id") == item_id:
			total += int(slot.amount)
	return total


func add(item_id: String, amount: int) -> int:
	var definition: Variant = registry.get_item(item_id)
	if definition == null or amount <= 0:
		return 0
	var remaining := amount
	for slot: Dictionary in slots:
		if slot.get("item_id") != item_id:
			continue
		var accepted := mini(remaining, definition.max_stack - int(slot.amount))
		slot.amount = int(slot.amount) + accepted
		remaining -= accepted
		if remaining == 0:
			return amount
	for index in range(slots.size()):
		if not slots[index].is_empty():
			continue
		var accepted := mini(remaining, definition.max_stack)
		slots[index] = {"item_id": item_id, "amount": accepted}
		remaining -= accepted
		if remaining == 0:
			break
	return amount - remaining


func remove(item_id: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var remaining := amount
	for index in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[index]
		if slot.get("item_id") != item_id:
			continue
		var removed := mini(remaining, int(slot.amount))
		var left := int(slot.amount) - removed
		remaining -= removed
		slots[index] = {} if left == 0 else {"item_id": item_id, "amount": left}
		if remaining == 0:
			break
	return amount - remaining


func snapshot() -> Array[Dictionary]:
	return slots.duplicate(true)
