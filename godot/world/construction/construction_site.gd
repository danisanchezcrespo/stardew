class_name ConstructionSite
extends RefCounted

const EPSILON := 0.0001

var instance_id := ""
var requirements: Dictionary = {}
var delivered: Dictionary = {}
var work_required_seconds := 0.0
var work_done_seconds := 0.0
var complete := false


func _init(id: String, material_requirements: Dictionary, required_work: float) -> void:
	instance_id = id
	requirements = material_requirements.duplicate(true)
	work_required_seconds = maxf(0.0, required_work)
	_update_complete()


func receivable(item_id: String) -> int:
	if complete:
		return 0
	return maxi(0, int(requirements.get(item_id, 0)) - int(delivered.get(item_id, 0)))


func deliver(item_id: String, amount: int) -> int:
	var accepted := mini(maxi(amount, 0), receivable(item_id))
	if accepted > 0:
		delivered[item_id] = int(delivered.get(item_id, 0)) + accepted
	_update_complete()
	return accepted


func materials_complete() -> bool:
	for item_id: String in requirements:
		if receivable(item_id) > 0:
			return false
	return true


func apply_work(seconds: float) -> float:
	if complete or not materials_complete() or seconds <= 0.0:
		return 0.0
	var accepted := minf(seconds, maxf(0.0, work_required_seconds - work_done_seconds))
	work_done_seconds += accepted
	_update_complete()
	return accepted


func material_progress() -> float:
	var total := 0
	var current := 0
	for item_id: String in requirements:
		total += int(requirements[item_id])
		current += mini(int(requirements[item_id]), int(delivered.get(item_id, 0)))
	return 1.0 if total == 0 else float(current) / float(total)


func work_progress() -> float:
	return 1.0 if work_required_seconds <= EPSILON else clampf(work_done_seconds / work_required_seconds, 0.0, 1.0)


func _update_complete() -> void:
	complete = materials_complete() and work_done_seconds + EPSILON >= work_required_seconds
