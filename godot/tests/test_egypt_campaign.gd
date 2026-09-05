extends SceneTree

const CampaignType = preload("res://world/progression/egypt_campaign.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var campaign := CampaignType.new()
	_expect(campaign.current_text().contains("Gather wood and clay"), "Campaign should begin with gathering guidance.", failures)
	campaign.record_pickup("wood")
	_expect(not campaign.completed.has("gather"), "Gathering requires both foundational resources.", failures)
	campaign.record_pickup("clay")
	campaign.record_craft("brick_kiln_plan")
	campaign.record_placement("BRICK_KILN")
	campaign.record_completion("BRICK_KILN")
	var machines := {
		"kiln": {"batches_completed": 1, "recipe_outputs": {"mud_bricks": 1}},
		"sawmill": {"batches_completed": 1, "recipe_outputs": {"planks": 2}},
		"farm": {"batches_completed": 1, "recipe_outputs": {"grain": 5}},
		"bakery": {"batches_completed": 1, "recipe_outputs": {"bread": 4}},
		"brewery": {"batches_completed": 1, "recipe_outputs": {"beer": 3}},
		"kitchen": {"batches_completed": 1, "recipe_outputs": {"food_ration": 5}}
		,"quarry": {"batches_completed": 1, "recipe_outputs": {"limestone": 4}}
		,"mine": {"batches_completed": 1, "recipe_outputs": {"copper_ore": 3}}
		,"smelter": {"batches_completed": 1, "recipe_outputs": {"copper_ingot": 2}}
		,"weaver": {"batches_completed": 1, "recipe_outputs": {"linen": 2}}
		,"papyrus": {"batches_completed": 1, "recipe_outputs": {"papyrus_sheet": 2}}
	}
	campaign.record_craft("bronze_tools")
	for entity_id: String in ["DWELLING", "SAWMILL", "GRAIN_FARM", "BAKERY", "BREWERY", "KITCHEN", "QUARRY", "COPPER_MINE", "COPPER_SMELTER", "WEAVER", "PAPYRUS_WORKSHOP", "SHRINE"]: campaign.record_completion(entity_id)
	campaign.refresh(machines, [{}, {}, {}], null, {"v1": {}, "v2": {}, "v3": {}, "v4": {}})
	_expect(campaign.is_complete(), "Full settlement loop should complete all campaign goals.", failures)
	_expect(campaign.current_text().contains("DYNASTY ESTABLISHED"), "Completion should produce a clear outcome.", failures)
	if failures.is_empty():
		print("PASS: egypt campaign")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
