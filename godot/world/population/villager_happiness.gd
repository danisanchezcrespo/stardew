class_name VillagerHappiness
extends RefCounted

const PROFILES := [
	{"id":"gardener","label":"Garden Soul","likes":["flowers","nature","water"],"hates":["industry","noise"],"preferred_jobs":["gardener","herbalist","beekeeper"]},
	{"id":"artisan","label":"Proud Artisan","likes":["statue","market","industry"],"hates":["isolation"],"preferred_jobs":["sculptor","blacksmith","builder"]},
	{"id":"traditionalist","label":"Old Traditions","likes":["monument","keep","quiet"],"hates":["flowers","market"],"preferred_jobs":["guard","miller"]},
	{"id":"merchant","label":"Village Socialite","likes":["market","neighbors","flowers"],"hates":["isolation","quiet"],"preferred_jobs":["merchant","baker","brewer"]},
	{"id":"naturalist","label":"Woodland Heart","likes":["nature","water","quiet"],"hates":["industry","market","statue"],"preferred_jobs":["animal keeper","beekeeper","gardener"]},
	{"id":"smith","label":"Practical Maker","likes":["industry","forge","market"],"hates":["flowers","water"],"preferred_jobs":["blacksmith","sculptor","miller"]},
]

static func profile_for(villager: Variant) -> Dictionary:
	# Personality belongs to the villager, not their clothes. This keeps wishes stable
	# if the player changes an appearance in the character panel.
	var id_text := str(villager.stable_id)
	var number := int(id_text.get_slice("-", 1)) if id_text.contains("-") else id_text.hash()
	return PROFILES[posmod(number, PROFILES.size())]

static func evaluate(villager: Variant, game: Node2D) -> Dictionary:
	var profile := profile_for(villager)
	var score := 50.0
	var positives: Array[String] = []
	var negatives: Array[String] = []
	if villager.hunger >= 65.0: score += 15.0; positives.append("Well fed  +15")
	elif villager.hunger < 30.0: score -= 24.0; negatives.append("Hungry  -24")
	if villager.energy >= 55.0: score += 10.0; positives.append("Well rested  +10")
	elif villager.energy < 25.0: score -= 16.0; negatives.append("Exhausted  -16")
	if not str(villager.home_id).is_empty(): score += 8.0; positives.append("Has a home  +8")
	else: score -= 18.0; negatives.append("No home  -18")
	if str(villager.profession) in profile.preferred_jobs: score += 12.0; positives.append("Favorite work  +12")
	elif str(villager.profession) != "generalist": score -= 5.0; negatives.append("Unfulfilling work  -5")
	var nearby := _nearby_tags(villager.home_position, str(villager.stable_id), game)
	for tag: String in profile.likes:
		if int(nearby.get(tag, 0)) > 0: score += 7.0; positives.append("Likes nearby %s  +7" % tag)
		elif tag == "isolation" and int(nearby.get("neighbors", 0)) == 0: score += 7.0; positives.append("Peaceful isolation  +7")
	for tag: String in profile.hates:
		if int(nearby.get(tag, 0)) > 0: score -= 9.0; negatives.append("Dislikes nearby %s  -9" % tag)
		elif tag == "isolation" and int(nearby.get("neighbors", 0)) == 0: score -= 9.0; negatives.append("Feels isolated  -9")
	var result_score := clampf(score, 0.0, 100.0)
	return {"score":result_score,"profile":profile,"positive":positives,"negative":negatives,"nearby":nearby}

static func _nearby_tags(origin: Vector2, own_id: String, game: Node2D) -> Dictionary:
	var tags := {"flowers":0,"nature":0,"water":0,"industry":0,"noise":0,"statue":0,"monument":0,"market":0,"keep":0,"neighbors":0,"quiet":0}
	var radius: float = float(game.CELL_SIZE) * 8.0
	for placed: Variant in game.world_grid.entities_by_id.values():
		var target: Variant = game.placed_targets.get(placed.instance_id)
		if target == null or origin.distance_to(target.global_position) > radius: continue
		var id := str(placed.definition_id)
		if id in ["FORGE","SCULPTOR_WORKSHOP","WINDMILL"]: tags.industry += 1; tags.noise += 1
		if id == "MARKET": tags.market += 1; tags.noise += 1
		if id == "KEEP": tags.keep += 1; tags.monument += 1
		if id.begins_with("DECOR_"):
			if id in ["DECOR_ROSES","DECOR_BLUEBELLS","DECOR_SUNFLOWERS","DECOR_LAVENDER","DECOR_TRELLIS","DECOR_HERB_POTS","DECOR_CHERRY_TREE","DECOR_FLOWERS","DECOR_TOPIARY"]: tags.flowers += 1; tags.nature += 1
			if id in ["DECOR_STONE_LION","DECOR_SCHOLAR","DECOR_KNIGHT","DECOR_STAG","DECOR_OBELISK","DECOR_SUNDIAL"]: tags.statue += 1; tags.monument += 1
			if id in ["DECOR_ANGEL_FOUNTAIN","DECOR_BIRDBATH"]: tags.water += 1
	for other: Variant in game.villagers.values():
		if other != null and str(other.stable_id) != own_id and origin.distance_to(other.home_position) <= radius: tags.neighbors += 1
	if int(tags.noise) == 0: tags.quiet = 1
	return tags
