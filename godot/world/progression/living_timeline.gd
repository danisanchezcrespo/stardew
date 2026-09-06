class_name LivingTimeline
extends RefCounted

const MAX_ENERGY := 100.0
const WEATHER := ["Clear", "Rain", "Mist", "Wind"]
const REQUESTS := [
	{"id":"edwin_stone", "from":"Edwin", "label":"Edwin is repairing the northern wall", "item":"field_stone", "amount":5, "reward":2},
	{"id":"mabel_bread", "from":"Mabel", "label":"Mabel wants bread for the village children", "item":"loaf", "amount":2, "reward":3},
	{"id":"alys_flour", "from":"Alys", "label":"Alys needs flour for the feast", "item":"flour", "amount":3, "reward":2},
	{"id":"hugh_tools", "from":"Hugh", "label":"Hugh needs tools for the harvest", "item":"iron_tools", "amount":1, "reward":4},
]

var enabled := false
var player_energy := MAX_ENERGY
var weather := "Clear"
var tomorrow_weather := "Rain"
var current_request: Dictionary = {}
var completed_requests: Dictionary = {}
var friendship: Dictionary = {}
var community := 0
var beauty := 0
var prosperity := 0
var feast_food := 0
var merchant_purchases: Dictionary = {}
var discoveries: Dictionary = {}

func configure(scenario_id: String, day: int) -> void:
	enabled = scenario_id == "medieval"
	if enabled: begin_day(day)

func begin_day(day: int) -> void:
	player_energy = MAX_ENERGY
	weather = WEATHER[(day - 1) % WEATHER.size()]
	tomorrow_weather = WEATHER[day % WEATHER.size()]
	current_request = {}
	for offset in range(REQUESTS.size()):
		var candidate: Dictionary = REQUESTS[(day - 1 + offset) % REQUESTS.size()]
		if not completed_requests.has(str(candidate.id)):
			current_request = candidate.duplicate(true)
			break

func spend_energy(amount: float) -> bool:
	if not enabled: return true
	if player_energy + 0.001 < amount: return false
	player_energy = maxf(0.0, player_energy - amount)
	return true

func restore_energy(amount: float) -> void:
	player_energy = minf(MAX_ENERGY, player_energy + amount)

func try_complete_request(inventory: Variant) -> Dictionary:
	if not enabled or current_request.is_empty(): return {}
	var item_id := str(current_request.item); var amount := int(current_request.amount)
	if inventory.count(item_id) < amount: return {}
	inventory.remove(item_id, amount)
	var request_id := str(current_request.id); var person := str(current_request.from)
	completed_requests[request_id] = true
	friendship[person] = int(friendship.get(person, 0)) + int(current_request.reward)
	community += int(current_request.reward)
	var result := current_request.duplicate(true)
	current_request = {}
	return result

func contribute_feast(inventory: Variant) -> int:
	if not enabled: return 0
	var delivered := mini(5, inventory.count("loaf"))
	if delivered > 0:
		inventory.remove("loaf", delivered); feast_food += delivered; community += delivered
	return delivered

func merchant_offer(day: int) -> Dictionary:
	if ((day - 1) % 8) + 1 != 6: return {}
	var cycle := floori((day - 1) / 8.0)
	return [
		{"item":"village_lantern", "label":"Village Lantern", "price":2},
		{"item":"village_bench", "label":"Village Bench", "price":3},
		{"item":"flower_bed", "label":"Flower Bed", "price":2},
	][cycle % 3]

func buy_merchant_offer(day: int, inventory: Variant) -> Dictionary:
	var offer := merchant_offer(day)
	if offer.is_empty() or merchant_purchases.has(str(day)): return {}
	var price := int(offer.price)
	if inventory.count("coin") < price or inventory.capacity_for(str(offer.item)) < 1: return {}
	inventory.remove("coin", price); inventory.add(str(offer.item), 1)
	merchant_purchases[str(day)] = true; prosperity += price
	return offer

func day_story(day: int) -> String:
	match day:
		1: return "A small valley, wary faces, and an empty village square. Earn their trust."
		2: return "The request board is open. Helping one person can change the whole village."
		3: return "Edwin saw blue fire near the northern ruins. The portal has been here before."
		4: return "Preparations begin for the Harvest Feast on Day 8. Bread will decide its success."
		5: return "The valley remembers your choices. Villagers now speak of you by name."
		6: return "A travelling merchant has reached the village with uncommon wares."
		7: return "Tomorrow is the feast. Finish what matters; not everything can be done."
		8: return "HARVEST FEAST - %s" % ("The valley celebrates a season of abundance." if feast_food >= 8 else "The meal is modest, but nobody faces the night alone.")
	return "The valley continues to grow around the choices you make."

func villager_story(person: String, day: int) -> String:
	var bond := int(friendship.get(person, 0))
	match person:
		"Alys": return "Alys studies the wind and dreams of becoming the valley's first miller." if bond < 3 else "Alys trusts you with her plan to restore the abandoned northern mill."
		"Edwin": return "Edwin distrusts miracles, especially the blue fire that brought you here." if bond < 3 else "Edwin admits he saw your portal years ago, on the night the old keep burned."
		"Mabel": return "Mabel remembers every hungry winter and measures hope in shared meals." if bond < 3 else "Mabel has begun recording your story so the valley will not forget you."
		"Hugh": return "Hugh believes a fine tool can change a person's fate." if bond < 3 else "Hugh offers to forge a key for the sealed chamber beneath the ruins."
	return "%s is still deciding what to make of the traveler." % person

func discover(item_id: String) -> String:
	if not enabled or item_id not in ["wild_herbs", "ruin_fragment"] or discoveries.has(item_id): return ""
	discoveries[item_id] = true
	if item_id == "ruin_fragment":
		prosperity += 2
		return "The carving matches the portal. Someone in this valley knew you before your arrival."
	community += 1
	return "Wild herbs can become gifts, remedies, or an offering for the feast."

func snapshot() -> Dictionary:
	return {"energy":player_energy,"weather":weather,"tomorrow":tomorrow_weather,"request":current_request.duplicate(true),"completed":completed_requests.duplicate(true),"friendship":friendship.duplicate(true),"community":community,"beauty":beauty,"prosperity":prosperity,"feast_food":feast_food,"merchant":merchant_purchases.duplicate(true),"discoveries":discoveries.duplicate(true)}

func restore(data: Dictionary) -> void:
	if data.is_empty(): return
	player_energy = float(data.get("energy", MAX_ENERGY)); weather = str(data.get("weather", "Clear")); tomorrow_weather = str(data.get("tomorrow", "Rain"))
	current_request = data.get("request", {}).duplicate(true); completed_requests = data.get("completed", {}).duplicate(true); friendship = data.get("friendship", {}).duplicate(true)
	community = int(data.get("community", 0)); beauty = int(data.get("beauty", 0)); prosperity = int(data.get("prosperity", 0)); feast_food = int(data.get("feast_food", 0))
	merchant_purchases = data.get("merchant", {}).duplicate(true)
	discoveries = data.get("discoveries", {}).duplicate(true)
