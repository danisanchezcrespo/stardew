class_name ItemIconAtlas
extends RefCounted

const TEXTURE = preload("res://assets/generated/items/egypt_item_icons.png")
const ECONOMY_TEXTURE = preload("res://assets/generated/items/egypt_economy_item_icons.png")
const CROP_TEXTURE = preload("res://assets/generated/crops/tree_growth_v3.png")
const INDUSTRY_TEXTURE = preload("res://assets/generated/items/egypt_industry_item_icons.png")
const MARS_TEXTURE = preload("res://assets/generated/mars/mars_items.png")
const PREHISTORY_TEXTURE = preload("res://assets/generated/prehistory/prehistory_content.png")
const MEDIEVAL_TEXTURE = preload("res://assets/generated/medieval/medieval_content.png")
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
const MARS_CELLS := {
	"martian_ice": Vector2i(0, 0), "mars_water": Vector2i(1, 0), "iron_ore": Vector2i(2, 0), "metal_plate": Vector2i(3, 0),
	"oxygen": Vector2i(0, 1), "energy_cell": Vector2i(1, 1), "algae": Vector2i(2, 1), "mars_ration": Vector2i(3, 1),
	"habitat_plan": Vector2i(0, 2), "ice_melter_plan": Vector2i(1, 2), "solar_array_plan": Vector2i(2, 2), "oxygen_extractor_plan": Vector2i(3, 2),
	"greenhouse_plan": Vector2i(0, 3), "fabricator_plan": Vector2i(1, 3), "comms_array_plan": Vector2i(2, 3), "mars_storage": Vector2i(3, 0),
}
const PREHISTORY_CELLS := {
	"branches": Vector2i(2, 2), "flint": Vector2i(1, 2), "spear": Vector2i(2, 1),
	"mammoth_meat": Vector2i(3, 1), "hide": Vector2i(0, 2), "smoked_meat": Vector2i(3, 2),
	"berries": Vector2i(0, 3), "campfire_plan": Vector2i(0, 0), "hide_shelter_plan": Vector2i(1, 0),
	"food_cache_plan": Vector2i(2, 0), "flint_workshop_plan": Vector2i(3, 0),
	"smoking_rack_plan": Vector2i(0, 1), "ritual_stones_plan": Vector2i(1, 1),
}
const MEDIEVAL_CELLS := {
	"wheat": Vector2i(2, 1), "flour": Vector2i(3, 1), "iron_ore_medieval": Vector2i(0, 2),
	"iron_tools": Vector2i(1, 2), "coin": Vector2i(2, 2), "loaf": Vector2i(3, 2),
	"oak_wood": Vector2i(0, 3), "field_stone": Vector2i(1, 3),
	"granary_plan": Vector2i(0, 0), "cottage_plan": Vector2i(1, 0), "windmill_plan": Vector2i(2, 0),
	"forge_plan": Vector2i(3, 0), "market_plan": Vector2i(0, 1), "keep_plan": Vector2i(1, 1),
}

static func texture(item_id: String) -> Texture2D:
	if item_id == "tree_seed": return CROP_TEXTURE
	if PREHISTORY_CELLS.has(item_id): return PREHISTORY_TEXTURE
	if MEDIEVAL_CELLS.has(item_id): return MEDIEVAL_TEXTURE
	if MARS_CELLS.has(item_id): return MARS_TEXTURE
	if INDUSTRY_CELLS.has(item_id): return INDUSTRY_TEXTURE
	return ECONOMY_TEXTURE if ECONOMY_CELLS.has(item_id) else TEXTURE

static func region(item_id: String) -> Rect2:
	var atlas := texture(item_id)
	if item_id == "tree_seed":
		return Rect2(0, 0, atlas.get_width() / 4.0, atlas.get_height())
	var cell: Vector2i = MEDIEVAL_CELLS.get(item_id, PREHISTORY_CELLS.get(item_id, MARS_CELLS.get(item_id, INDUSTRY_CELLS.get(item_id, ECONOMY_CELLS.get(item_id, CELLS.get(item_id, Vector2i.ZERO))))))
	var columns := 4.0 if MEDIEVAL_CELLS.has(item_id) or PREHISTORY_CELLS.has(item_id) or INDUSTRY_CELLS.has(item_id) or MARS_CELLS.has(item_id) else 3.0
	var size := Vector2(atlas.get_width() / columns, atlas.get_height() / columns)
	return Rect2(Vector2(cell) * size, size)

static func icon(item_id: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture(item_id)
	result.region = region(item_id)
	return result
