class_name PhysicalWorkforce
extends RefCounted

var population := 1
var jobs: Dictionary = {}
var assignments: Dictionary = {}
var food_reserve := 0.0
var hungry := false

func add_food(amount: int) -> int:
	if amount <= 0: return 0
	food_reserve += amount
	hungry = false
	rebalance()
	return amount

func process(delta: float) -> void:
	food_reserve = maxf(0.0, food_reserve - maxf(delta, 0.0) * population * 0.01)
	var was_hungry := hungry
	hungry = population > 1 and food_reserve <= 0.0
	if hungry != was_hungry: rebalance()

func register_job(instance_id: String, workers_required: int, priority: int = 0) -> void:
	jobs[instance_id] = {"required": maxi(workers_required, 0), "priority": priority}
	rebalance()

func set_population(value: int) -> void:
	population = maxi(value, 0)
	rebalance()

func rebalance() -> void:
	assignments.clear()
	var ids: Array = jobs.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return int(jobs[a].priority) > int(jobs[b].priority))
	var available := maxi(1, ceili(population * 0.5)) if hungry else population
	for instance_id: String in ids:
		var required: int = int(jobs[instance_id].required)
		var assigned := mini(required, available)
		assignments[instance_id] = assigned
		available -= assigned

func assigned_to(instance_id: String) -> int:
	return int(assignments.get(instance_id, 0))

func employment_summary() -> String:
	var employed := 0
	for amount: Variant in assignments.values():
		employed += int(amount)
	return "%d population | %d employed | Food %.1f%s" % [population, employed, food_reserve, " HUNGRY" if hungry else ""]
