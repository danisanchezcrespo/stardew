class_name ItemIconAtlas
extends RefCounted

const TEXTURE = preload("res://assets/generated/items/egypt_item_icons.png")
const CELLS := {
	"wood": Vector2i(0, 0), "clay": Vector2i(1, 0), "grain": Vector2i(2, 0),
	"mud_bricks": Vector2i(0, 1), "storage_crate": Vector2i(1, 1), "brick_kiln_plan": Vector2i(2, 1),
	"dwelling_plan": Vector2i(0, 2), "food_ration": Vector2i(1, 2), "shrine_plan": Vector2i(2, 2),
}

static func region(item_id: String) -> Rect2:
	var cell: Vector2i = CELLS.get(item_id, Vector2i.ZERO)
	var size := Vector2(TEXTURE.get_width() / 3.0, TEXTURE.get_height() / 3.0)
	return Rect2(Vector2(cell) * size, size)

static func icon(item_id: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = TEXTURE
	result.region = region(item_id)
	return result
