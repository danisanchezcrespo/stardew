class_name SeasonalWeatherFx
extends Node2D

var game: Node2D


func configure(owner_game: Node2D) -> void:
	game = owner_game; z_as_relative = false; z_index = -3000; queue_redraw()


func _process(_delta: float) -> void:
	if game != null and game.living_timeline != null and game.living_timeline.enabled: queue_redraw()


func _draw() -> void:
	if game == null or game.timeline_director == null or not game.timeline_director.enabled: return
	var season: String = game.meta_progression.season_name()
	var weather: String = game.living_timeline.weather
	var phase: float = game.day_time_seconds * 7.0
	if season == "Winter":
		draw_rect(Rect2(Vector2.ZERO, game.WORLD_PIXELS), Color(0.88, 0.94, 1.0, 0.58))
		for index in range(150):
			var x: float = fmod(float(index * 137) + phase * (0.7 + float(index % 4) * 0.14), game.WORLD_PIXELS.x)
			var y: float = fmod(float(index * 83) + phase * (1.0 + float(index % 3) * 0.2), game.WORLD_PIXELS.y)
			draw_circle(Vector2(x, y), 1.5 + float(index % 3), Color(1, 1, 1, 0.82))
	elif weather in ["Rain", "Storm"] or (season == "Summer" and game.meta_progression.day % 6 == 0):
		draw_rect(Rect2(Vector2.ZERO, game.WORLD_PIXELS), Color(0.12, 0.22, 0.30, 0.18 if weather != "Storm" else 0.3))
		for index in range(120 if weather != "Storm" else 190):
			var x: float = fmod(float(index * 109) + phase * 2.4, game.WORLD_PIXELS.x)
			var y: float = fmod(float(index * 71) + phase * 4.5, game.WORLD_PIXELS.y)
			draw_line(Vector2(x, y), Vector2(x - 7, y + 18), Color(0.65, 0.84, 1.0, 0.62), 2.0)
	elif weather == "Eclipse":
		draw_rect(Rect2(Vector2.ZERO, game.WORLD_PIXELS), Color(0.16, 0.10, 0.24, 0.48))
	# The weekend is visibly different even before dedicated market buildings exist.
	if game.meta_progression.weekday_name() in ["Saturday", "Sunday"]:
		var center := Vector2(650, 340)
		for index in range(7):
			var color := Color("#d64f4f") if index % 2 == 0 else Color("#f0c85a")
			draw_colored_polygon(PackedVector2Array([center + Vector2(index * 24 - 78, -70), center + Vector2(index * 24 - 66, -50), center + Vector2(index * 24 - 54, -70)]), color)
	if game.timeline_director.memories.has("northern_door_open"):
		draw_circle(Vector2(1424, 160), 26.0, Color(0.15, 0.08, 0.04, 0.8)); draw_arc(Vector2(1424, 160), 27.0, PI, TAU, 20, Color("#8a7658"), 5.0)
	if game.timeline_director.memories.has("project_public_gardens"):
		for index in range(18): draw_circle(Vector2(470 + (index % 6) * 22, 470 + (index / 6) * 20), 6.0, [Color("#e2768f"), Color("#efd76f"), Color("#8fcf75")][index % 3])
	if game.timeline_director.memories.has("project_great_market"):
		for index in range(5): draw_rect(Rect2(780 + index * 42, 315, 30, 24), Color("#b64e43") if index % 2 == 0 else Color("#e3bb58"))
	if game.timeline_director.memories.has("project_fortified_village"):
		draw_polyline(PackedVector2Array([Vector2(330,590),Vector2(330,250),Vector2(1120,250),Vector2(1120,590)]), Color("#7d7a71"), 12.0)
	if game.timeline_director.memories.has("project_restored_mill"):
		draw_circle(Vector2(1110, 285), 30.0, Color("#ad8b55")); draw_line(Vector2(1110,245),Vector2(1110,325),Color("#e2d5af"),8.0); draw_line(Vector2(1070,285),Vector2(1150,285),Color("#e2d5af"),8.0)
	if game.timeline_director.memories.has("project_harvest_hall"):
		draw_rect(Rect2(780, 520, 190, 70), Color("#8d5b35")); draw_colored_polygon(PackedVector2Array([Vector2(760,520),Vector2(875,455),Vector2(990,520)]),Color("#7c342a"))
	if game.timeline_director.memories.has("project_scholars_archive"):
		draw_rect(Rect2(1050, 420, 120, 130), Color("#827f78")); draw_circle(Vector2(1110,455),20.0,Color("#648ba5"))
	if game.meta_progression.season_name() == "Autumn" and game.meta_progression.day == 28:
		var feast := Vector2(680, 370)
		draw_rect(Rect2(feast - Vector2(105, 18), Vector2(210, 36)), Color("#8a4f2b")); draw_rect(Rect2(feast - Vector2(98, 13), Vector2(196, 26)), Color("#e0c080"))
		for index in range(8): draw_circle(feast + Vector2(-84 + index * 24, 0), 5.0, Color("#cf6a3f") if index % 2 == 0 else Color("#f0d36c"))
