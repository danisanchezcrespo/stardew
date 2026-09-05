class_name ItemIconAtlas
extends RefCounted

const TEXTURE = preload("res://assets/generated/items/egypt_item_icons.png")
const ECONOMY_TEXTURE = preload("res://assets/generated/items/egypt_economy_item_icons.png")
const CROP_TEXTURE = preload("res://assets/generated/crops/tree_growth_v2.png")
const CELLS := {
	"wood": Vector2i(0, 0), "clay": Vector2i(1, 0), "grain": Vector2i(2, 0),
	"mud_bricks": Vector2i(0, 1), "storage_crate": Vector2i(1, 1), "brick_kiln_plan": Vector2i(2, 1),
	"dwelling_plan": Vector2i(0, 2), "food_ration": Vector2i(1, 2), "shrine_plan": Vector2i(2, 2),
}
const ECONOMY_CELLS := {
	"water": Vector2i(0, 0), "bread": Vector2i(1, 0), "beer": Vector2i(2, 0),
	"planks": Vector2i(0, 1), "grain_farm_plan": Vector2i(1, 1), "bakery_plan": Vector2i(2, 1),
	"brewery_plan": Vector2i(0, 2), "kitchen_plan": Vector2i(1, 2), "sawmill_plan": Vector2i(2, 2),
}

static func texture(item_id: String) -> Texture2D:
	if item_id == "tree_seed": return CROP_TEXTURE
	return ECONOMY_TEXTURE if ECONOMY_CELLS.has(item_id) else TEXTURE

static func region(item_id: String) -> Rect2:
	var atlas := texture(item_id)
	if item_id == "tree_seed":
		return Rect2(0, 0, atlas.get_width() / 4.0, atlas.get_height())
	var cell: Vector2i = ECONOMY_CELLS.get(item_id, CELLS.get(item_id, Vector2i.ZERO))
	var size := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 3.0)
	return Rect2(Vector2(cell) * size, size)

static func icon(item_id: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture(item_id)
	result.region = region(item_id)
	return result
