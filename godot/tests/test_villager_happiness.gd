extends SceneTree

const HappinessType = preload("res://world/population/villager_happiness.gd")

class FakeWorld:
	extends RefCounted
	var entities_by_id := {}

class FakeGame:
	extends Node2D
	const CELL_SIZE := 32
	var world_grid := FakeWorld.new()
	var placed_targets := {}
	var villagers := {}

class FakePlaced:
	extends RefCounted
	var instance_id := ""
	var definition_id := ""

class FakeVillager:
	extends RefCounted
	var stable_id := "villager-0"
	var appearance_id := 0
	var hunger := 80.0
	var energy := 80.0
	var home_id := "home"
	var home_position := Vector2.ZERO
	var profession := "generalist"

func _initialize() -> void:
	var failures: Array[String] = []
	var game := FakeGame.new(); root.add_child(game)
	var gardener := FakeVillager.new(); gardener.stable_id = "villager-0"; game.villagers[gardener.stable_id] = gardener
	var baseline := HappinessType.evaluate(gardener, game)
	_add_placeable(game, "rose-1", "DECOR_ROSES", Vector2(32, 0))
	var flower_gardener := HappinessType.evaluate(gardener, game)
	_expect(float(flower_gardener.score) > float(baseline.score), "A Garden Soul should gain happiness from nearby flowers.", failures)
	var traditionalist := FakeVillager.new(); traditionalist.stable_id = "villager-2"
	game.villagers.clear(); game.villagers[traditionalist.stable_id] = traditionalist
	var flower_traditionalist := HappinessType.evaluate(traditionalist, game)
	game.world_grid.entities_by_id.clear(); game.placed_targets.clear()
	var clear_traditionalist := HappinessType.evaluate(traditionalist, game)
	_expect(float(flower_traditionalist.score) < float(clear_traditionalist.score), "An Old Traditions villager should dislike nearby flowers.", failures)
	var hungry := FakeVillager.new(); hungry.stable_id = "villager-0"; hungry.hunger = 5.0
	_expect(float(HappinessType.evaluate(hungry, game).score) < float(baseline.score), "Hunger should materially reduce happiness.", failures)
	_expect(HappinessType.profile_for(gardener).id == HappinessType.profile_for(hungry).id, "Appearance-independent stable ids should produce stable personalities.", failures)
	game.queue_free()
	if failures.is_empty(): print("PASS: villager happiness"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)

func _add_placeable(game: FakeGame, instance_id: String, definition_id: String, position: Vector2) -> void:
	var placed := FakePlaced.new(); placed.instance_id = instance_id; placed.definition_id = definition_id
	var target := Node2D.new(); target.global_position = position; game.add_child(target)
	game.world_grid.entities_by_id[instance_id] = placed; game.placed_targets[instance_id] = target

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
