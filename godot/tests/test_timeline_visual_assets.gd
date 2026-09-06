extends SceneTree

const ASSETS := [
	"res://assets/generated/medieval/chicken_coop.png",
	"res://assets/generated/medieval/herb_garden.png",
	"res://assets/generated/medieval/apiary.png",
	"res://assets/generated/medieval/astronomer_tower.png",
]

func _initialize() -> void:
	var failures: Array[String] = []
	for path: String in ASSETS:
		var texture := load(path) as Texture2D
		if texture == null:
			failures.append("Missing timeline visual: %s" % path)
			continue
		var image := texture.get_image()
		var transparent := 0
		var colored := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a < 0.05: transparent += 1
				elif maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) > 0.08: colored += 1
		if transparent == 0 or colored == 0: failures.append("Timeline visual lost transparency or color: %s" % path)
	if failures.is_empty(): print("PASS: timeline visual assets"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)
