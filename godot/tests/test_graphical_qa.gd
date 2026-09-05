extends SceneTree

const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")

const SHEETS := [
	"res://assets/generated/prehistory/prehistory_hunter.png",
	"res://assets/generated/prehistory/prehistory_hunter_female.png",
	"res://assets/generated/medieval/medieval_character.png",
	"res://assets/generated/medieval/medieval_character_female.png",
	"res://assets/generated/mars/mars_colonist.png",
	"res://assets/generated/mars/mars_colonist_female.png",
]


func _initialize() -> void:
	var failures: Array[String] = []
	for path: String in SHEETS:
		_validate_sheet(path, failures)
	_validate_mammoth(failures)
	_validate_medieval_resources(failures)
	_expect(ResourceLoader.exists("res://assets/fonts/settlement_pixel_font.fnt"), "The texture font must be importable.", failures)
	_expect(ResourceLoader.exists("res://assets/generated/buildings/chicken_coop.png"), "Chicken coop must have a dedicated sprite.", failures)
	if failures.is_empty():
		print("PASS: graphical QA (240 player frames and mammoth atlas)")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)


func _validate_sheet(path: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_expect(image.get_size() == Vector2i(640, 320), "%s must be a 10x4 atlas of 64x80 frames" % path, failures)
	if image.get_size() != Vector2i(640, 320): return
	for row in range(4):
		for column in range(10):
			var frame := image.get_region(Rect2i(column * 64, row * 80, 64, 80))
			var used := frame.get_used_rect()
			_expect(used.has_area(), "%s frame %d,%d is empty" % [path, column, row], failures)
			_expect(used.position.x > 0 and used.end.x < 64, "%s frame %d,%d clips horizontally" % [path, column, row], failures)


func _validate_mammoth(failures: Array[String]) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/generated/prehistory/mammoth.png"))
	_expect(image.get_size() == Vector2i(512, 128), "Mammoth atlas must contain four 128px cells", failures)
	if image.get_size() != Vector2i(512, 128): return
	for column in range(4):
		var used := image.get_region(Rect2i(column * 128, 0, 128, 128)).get_used_rect()
		_expect(used.has_area(), "Mammoth cell %d is empty" % column, failures)
		_expect(used.position.x >= 7 and used.end.x <= 121, "Mammoth cell %d clips horizontally" % column, failures)
		_expect(used.position.y >= 7 and used.end.y <= 121, "Mammoth cell %d clips vertically" % column, failures)


func _validate_medieval_resources(failures: Array[String]) -> void:
	var wood := ItemIconAtlasType.icon("oak_wood")
	var stone := ItemIconAtlasType.icon("field_stone")
	_expect(wood.atlas.resource_path.ends_with("medieval_resources.png"), "Oak wood must use the medieval resource atlas, not a plan cell", failures)
	_expect(stone.atlas.resource_path.ends_with("medieval_resources.png"), "Field stone must use the medieval resource atlas, not a plan cell", failures)
	_expect(wood.region == Rect2(0, 0, 128, 128), "Oak wood must use the log cell", failures)
	_expect(stone.region == Rect2(128, 0, 128, 128), "Field stone must use the stone cell", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
