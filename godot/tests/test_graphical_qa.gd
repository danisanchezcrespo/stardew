extends SceneTree

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
	_expect(image.get_width() % 4 == 0, "Mammoth atlas must contain four equal columns", failures)
	_expect(image.get_height() > image.get_width() / 8, "Mammoth atlas must retain its full vertical artwork", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
