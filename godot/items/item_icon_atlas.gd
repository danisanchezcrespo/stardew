class_name ItemIconAtlas
extends RefCounted

const TEXTURE = preload("res://assets/generated/items/egypt_item_icons.png")
const ECONOMY_TEXTURE = preload("res://assets/generated/items/egypt_economy_item_icons.png")
const CROP_TEXTURE = preload("res://assets/generated/crops/tree_growth_v3.png")
const INDUSTRY_TEXTURE = preload("res://assets/generated/items/egypt_industry_item_icons.png")
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
const INDUSTRY_CELLS := {
	"limestone": Vector2i(0, 0), "stone_blocks": Vector2i(1, 0), "copper_ore": Vector2i(2, 0), "copper_ingot": Vector2i(3, 0),
	"flax": Vector2i(0, 1), "linen": Vector2i(1, 1), "papyrus_reeds": Vector2i(2, 1), "papyrus_sheet": Vector2i(3, 1),
	"bronze_tools": Vector2i(0, 2), "quarry_plan": Vector2i(1, 2), "copper_mine_plan": Vector2i(2, 2), "smelter_plan": Vector2i(3, 2),
	"weaver_plan": Vector2i(0, 3), "papyrus_workshop_plan": Vector2i(1, 3),
}

static func texture(item_id: String) -> Texture2D:
	if item_id == "tree_seed": return CROP_TEXTURE
	if INDUSTRY_CELLS.has(item_id): return INDUSTRY_TEXTURE
	return ECONOMY_TEXTURE if ECONOMY_CELLS.has(item_id) else TEXTURE

static func region(item_id: String) -> Rect2:
	var atlas := texture(item_id)
	if item_id == "tree_seed":
		return Rect2(0, 0, atlas.get_width() / 4.0, atlas.get_height())
	var cell: Vector2i = INDUSTRY_CELLS.get(item_id, ECONOMY_CELLS.get(item_id, CELLS.get(item_id, Vector2i.ZERO)))
	var columns := 4.0 if INDUSTRY_CELLS.has(item_id) else 3.0
	var size := Vector2(atlas.get_width() / columns, atlas.get_height() / columns)
	return Rect2(Vector2(cell) * size, size)

static func icon(item_id: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture(item_id)
	result.region = region(item_id)
	return result
