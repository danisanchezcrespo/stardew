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
	campaign.refresh({"kiln": {"batches_completed": 1}}, [])
	campaign.record_completion("DWELLING")
	campaign.refresh({}, [{"route_id": "route-1"}])
	campaign.record_completion("SHRINE")
	_expect(campaign.is_complete(), "Full settlement loop should complete all campaign goals.", failures)
	_expect(campaign.current_text().contains("SETTLEMENT ESTABLISHED"), "Completion should produce a clear outcome.", failures)
	if failures.is_empty():
		print("PASS: egypt campaign")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
