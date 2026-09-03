class_name InteractionTargeting
extends RefCounted


static func select_target(player_position: Vector2, facing: String, candidates: Array, reach_px: float) -> Variant:
	var direction := _facing_vector(facing)
	var best: Variant = null
	var best_facing := false
	var best_distance := INF
	var best_id := ""
	for candidate: Variant in candidates:
		if candidate == null or not candidate.has_method("is_interactable") or not candidate.is_interactable():
			continue
		var offset: Vector2 = candidate.interaction_position() - player_position
		var distance := offset.length()
		if distance > reach_px:
			continue
		var in_facing_half_plane := offset.is_zero_approx() or offset.dot(direction) >= 0.0
		var candidate_id: String = candidate.stable_id
		if best == null or _is_better(in_facing_half_plane, distance, candidate_id, best_facing, best_distance, best_id):
			best = candidate
			best_facing = in_facing_half_plane
			best_distance = distance
			best_id = candidate_id
	return best


static func _is_better(candidate_facing: bool, candidate_distance: float, candidate_id: String, best_facing: bool, best_distance: float, best_id: String) -> bool:
	if candidate_facing != best_facing:
		return candidate_facing
	if not is_equal_approx(candidate_distance, best_distance):
		return candidate_distance < best_distance
	return candidate_id < best_id


static func _facing_vector(facing: String) -> Vector2:
	match facing:
		"north": return Vector2.UP
		"east": return Vector2.RIGHT
		"west": return Vector2.LEFT
	return Vector2.DOWN
