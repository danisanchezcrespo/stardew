class_name LivingTimeline
extends RefCounted

const MAX_ENERGY := 100.0
const WEATHER := ["Clear", "Rain", "Mist", "Wind"]
const PEOPLE := ["Alys", "Edwin", "Mabel", "Hugh"]
const GIFT_TASTES := {
	"Alys":{"loves":["flour", "wild_herbs"], "likes":["loaf", "wheat"]},
	"Edwin":{"loves":["iron_tools", "ruin_fragment"], "likes":["field_stone", "loaf"]},
	"Mabel":{"loves":["loaf", "flower_bed"], "likes":["wild_herbs", "flour"]},
	"Hugh":{"loves":["iron_tools", "oak_wood"], "likes":["field_stone", "loaf"]},
}
const SELL_VALUES := {"wild_herbs":2, "wheat":1, "flour":2, "loaf":3, "field_stone":1, "oak_wood":1, "iron_tools":5, "egg":2, "honey":4, "medicinal_herbs":4, "chicken_meat":4, "star_chart":8, "festival_platter":7}
const DAILY_EVENTS := [
	"The market is lively: goods sell for one extra coin today.",
	"A cool breeze settles over the valley. Travel costs less energy.",
	"The ruins gleam after dusk. Exploration is more likely to reveal a relic.",
	"The village is quiet. Gifts earn an extra point of affection.",
	"A perfectly ordinary day - valuable in its own way.",
]
const REQUESTS := [
	{"id":"edwin_stone", "from":"Edwin", "label":"Edwin is repairing the northern wall", "item":"field_stone", "amount":5, "reward":2},
	{"id":"mabel_bread", "from":"Mabel", "label":"Mabel wants bread for the village children", "item":"loaf", "amount":2, "reward":3},
	{"id":"alys_flour", "from":"Alys", "label":"Alys needs flour for the feast", "item":"flour", "amount":3, "reward":2},
	{"id":"hugh_tools", "from":"Hugh", "label":"Hugh needs tools for the harvest", "item":"iron_tools", "amount":1, "reward":4},
]

var enabled := false
var player_energy := MAX_ENERGY
var max_energy := MAX_ENERGY
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
var conversations: Dictionary = {}
var gifts_today: Dictionary = {}
var skill_xp := {"foraging":0, "crafting":0, "exploration":0, "community":0}
var tool_levels := {"foraging":1, "crafting":1, "exploration":1}
var home_level := 0
var home_style := "Hearthwood"
var exploration_attempts := 2
var exploration_depth := 0
var daily_event := ""
var days_played := 0

func configure(scenario_id: String, day: int) -> void:
	enabled = scenario_id == "medieval"
	if enabled: begin_day(day)

func begin_day(day: int) -> void:
	player_energy = max_energy
	weather = WEATHER[(day - 1) % WEATHER.size()]
	tomorrow_weather = WEATHER[day % WEATHER.size()]
	current_request = {}
	gifts_today.clear()
	exploration_attempts = 2 + (1 if int(tool_levels.exploration) >= 3 else 0)
	daily_event = DAILY_EVENTS[(day * 3 + community + beauty) % DAILY_EVENTS.size()]
	days_played = maxi(days_played, day)
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
	player_energy = minf(max_energy, player_energy + amount)

func skill_level(skill: String) -> int:
	return 1 + int(skill_xp.get(skill, 0)) / 20

func action_cost(base_cost: float, tool: String) -> float:
	return maxf(1.0, base_cost - float(int(tool_levels.get(tool, 1)) - 1) * 0.5)

func add_skill_xp(skill: String, amount: int) -> bool:
	var before := skill_level(skill)
	skill_xp[skill] = int(skill_xp.get(skill, 0)) + amount
	return skill_level(skill) > before

func talk_to(person: String, day: int) -> Dictionary:
	if person.is_empty(): return {}
	var key := "%d:%s" % [day, person]
	var repeated := conversations.has(key)
	conversations[key] = true
	if not repeated:
		friendship[person] = int(friendship.get(person, 0)) + 1
		add_skill_xp("community", 2)
	var lines: Dictionary = {
		"Alys":["The millstones sing differently before rain.", "I want to make flour fine enough for a royal table.", "The north mill was abandoned long before I was born."],
		"Edwin":["Stone remembers every hand that shaped it.", "Those blue lights by the ruin are no marsh fire.", "A strong wall matters less than who stands behind it."],
		"Mabel":["A warm loaf can settle an argument before it begins.", "Children notice every kindness adults pretend to miss.", "Bring me herbs and I will show you an old valley remedy."],
		"Hugh":["A blunt tool wastes daylight and patience.", "Good iron has a voice. You learn to hear it.", "There is a lock beneath the ruin that no village key can open."],
	}
	var heart := heart_level(person)
	var person_lines: Array = lines.get(person, ["Every day this place feels a little more like home.", "The village changes when people choose to care for it.", "I wonder what other ages you have seen."])
	return {"person":person, "new":not repeated, "text":person_lines[mini(heart, 2)], "hearts":heart}

func give_gift(person: String, item_id: String, inventory: Variant) -> Dictionary:
	if person.is_empty() or item_id.is_empty() or gifts_today.has(person) or inventory.count(item_id) <= 0: return {}
	var tastes: Dictionary = GIFT_TASTES.get(person, {"loves":["loaf"], "likes":["wild_herbs", "flour"]})
	var points := 1
	var reaction := "Thank you. I will remember the thought."
	if item_id in tastes.loves: points = 4; reaction = "You remembered! This means more than you know."
	elif item_id in tastes.likes: points = 2; reaction = "This will be useful. Thank you."
	if daily_event.begins_with("The village is quiet"): points += 1
	inventory.remove(item_id, 1); gifts_today[person] = true
	friendship[person] = int(friendship.get(person, 0)) + points
	add_skill_xp("community", points)
	return {"person":person, "points":points, "reaction":reaction, "hearts":heart_level(person)}

func heart_level(person: String) -> int:
	return clampi(int(friendship.get(person, 0)) / 4, 0, 10)

func schedule_for(person: String, hour: int, weather_now: String) -> String:
	if hour < 7: return "sleeping at home"
	if weather_now == "Rain" and hour < 17: return "sheltering in the cottage"
	if hour < 9: return "having breakfast"
	if hour < 13: return {"Alys":"working near the windmill", "Edwin":"checking the northern wall", "Mabel":"baking at the hearth", "Hugh":"working at the forge"}.get(person, "working")
	if hour < 14: return "eating in the village square"
	if hour < 18: return "visiting neighbors and working"
	if hour < 21: return "resting by a lantern or bench" if beauty >= 2 else "returning home"
	return "sleeping at home"

func explore(inventory: Variant, day: int) -> Dictionary:
	if not enabled or exploration_attempts <= 0: return {}
	var cost := maxf(4.0, 12.0 - float(tool_levels.exploration) * 2.0)
	if not spend_energy(cost): return {"error":"You are too exhausted to search the ruins."}
	exploration_attempts -= 1; exploration_depth += 1; add_skill_xp("exploration", 4)
	var lucky := daily_event.begins_with("The ruins gleam")
	var reward := "field_stone"
	if (day + exploration_depth + int(tool_levels.exploration) + (2 if lucky else 0)) % 4 == 0: reward = "ruin_fragment"
	elif exploration_depth % 3 == 0: reward = "wild_herbs"
	var amount := 2 if reward == "field_stone" else 1
	if inventory.capacity_for(reward) < amount: return {"error":"Your inventory is full; the find remains hidden."}
	inventory.add(reward, amount)
	return {"item":reward, "amount":amount, "depth":exploration_depth}

func sell(item_id: String, inventory: Variant) -> Dictionary:
	if not SELL_VALUES.has(item_id) or inventory.count(item_id) <= 0: return {}
	var price := int(SELL_VALUES[item_id]) + (1 if daily_event.begins_with("The market is lively") else 0)
	if inventory.capacity_for("coin") <= 0: return {}
	inventory.remove(item_id, 1); inventory.add("coin", price); prosperity += price
	return {"item":item_id, "coins":price}

func upgrade_tool(tool: String, inventory: Variant) -> Dictionary:
	if tool not in tool_levels: return {}
	var level := int(tool_levels[tool]); var coin_cost := level * 4; var tool_cost := level
	if level >= 4 or inventory.count("coin") < coin_cost or inventory.count("iron_tools") < tool_cost: return {}
	inventory.remove("coin", coin_cost); inventory.remove("iron_tools", tool_cost); tool_levels[tool] = level + 1
	return {"tool":tool, "level":level + 1, "coins":coin_cost}

func improve_home(inventory: Variant) -> Dictionary:
	var coin_cost := (home_level + 1) * 5; var wood_cost := (home_level + 1) * 3
	if home_level >= 3 or inventory.count("coin") < coin_cost or inventory.count("oak_wood") < wood_cost: return {}
	inventory.remove("coin", coin_cost); inventory.remove("oak_wood", wood_cost); home_level += 1; beauty += 2
	return {"level":home_level, "coins":coin_cost, "wood":wood_cost}

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
	var points := 0
	for row: Dictionary in [{"item":"festival_platter","value":5},{"item":"honey","value":2},{"item":"egg","value":1},{"item":"loaf","value":1}]:
		var amount := mini(5, inventory.count(str(row.item)))
		if amount > 0: inventory.remove(str(row.item), amount); points += amount * int(row.value)
	if points > 0: feast_food += points; community += points
	return points

func merchant_offer(day: int) -> Dictionary:
	if ((day - 1) % 8) + 1 != 6: return {}
	var cycle := floori((day - 1) / 8.0)
	return [
		{"item":"village_lantern", "label":"Village Lantern", "price":2},
		{"item":"village_bench", "label":"Village Bench", "price":3},
		{"item":"flower_bed", "label":"Flower Bed", "price":2},
		{"effect":"map", "label":"Hand-drawn Ruin Map", "price":5},
		{"effect":"satchel", "label":"Pilgrim's Satchel", "price":8},
		{"effect":"tapestry", "label":"Woven Cottage Tapestry", "price":6},
	][cycle % 6]

func buy_merchant_offer(day: int, inventory: Variant) -> Dictionary:
	var offer := merchant_offer(day)
	if offer.is_empty() or merchant_purchases.has(str(day)): return {}
	var price := int(offer.price)
	if inventory.count("coin") < price: return {}
	if offer.has("item") and inventory.capacity_for(str(offer.item)) < 1: return {}
	inventory.remove("coin", price)
	if offer.has("item"): inventory.add(str(offer.item), 1)
	match str(offer.get("effect", "")):
		"map": exploration_attempts += 1; tool_levels.exploration = mini(4, int(tool_levels.exploration) + 1)
		"satchel": max_energy += 20.0; player_energy += 20.0
		"tapestry": beauty += 4; home_style = "Woven Gold"
	merchant_purchases[str(day)] = true; prosperity += price
	return offer

func day_story(day: int, season: String = "Spring") -> String:
	if season == "Autumn" and day == 28:
		return "HARVEST FEAST - %s" % ("The valley celebrates a season of abundance." if feast_food >= 8 else "The meal is modest, but nobody faces the night alone.")
	if day == 1:
		return {"Spring":"New shoots and new promises appear across the valley.", "Summer":"Long days invite bold plans, but storms gather quickly.", "Autumn":"The harvest season begins. Store food and prepare the feast.", "Winter":"Snow quiets the valley. What was prepared now matters."}.get(season, "A new chapter begins in the valley.")
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
	return {"energy":player_energy,"max_energy":max_energy,"weather":weather,"tomorrow":tomorrow_weather,"request":current_request.duplicate(true),"completed":completed_requests.duplicate(true),"friendship":friendship.duplicate(true),"community":community,"beauty":beauty,"prosperity":prosperity,"feast_food":feast_food,"merchant":merchant_purchases.duplicate(true),"discoveries":discoveries.duplicate(true),"conversations":conversations.duplicate(true),"gifts_today":gifts_today.duplicate(true),"skill_xp":skill_xp.duplicate(true),"tool_levels":tool_levels.duplicate(true),"home_level":home_level,"home_style":home_style,"exploration_attempts":exploration_attempts,"exploration_depth":exploration_depth,"daily_event":daily_event,"days_played":days_played}

func restore(data: Dictionary) -> void:
	if data.is_empty(): return
	max_energy = float(data.get("max_energy", MAX_ENERGY)); player_energy = float(data.get("energy", max_energy)); weather = str(data.get("weather", "Clear")); tomorrow_weather = str(data.get("tomorrow", "Rain"))
	current_request = data.get("request", {}).duplicate(true); completed_requests = data.get("completed", {}).duplicate(true); friendship = data.get("friendship", {}).duplicate(true)
	community = int(data.get("community", 0)); beauty = int(data.get("beauty", 0)); prosperity = int(data.get("prosperity", 0)); feast_food = int(data.get("feast_food", 0))
	merchant_purchases = data.get("merchant", {}).duplicate(true)
	discoveries = data.get("discoveries", {}).duplicate(true)
	conversations = data.get("conversations", {}).duplicate(true); gifts_today = data.get("gifts_today", {}).duplicate(true)
	skill_xp = data.get("skill_xp", skill_xp).duplicate(true); tool_levels = data.get("tool_levels", tool_levels).duplicate(true)
	home_level = int(data.get("home_level", 0)); home_style = str(data.get("home_style", "Hearthwood"))
	exploration_attempts = int(data.get("exploration_attempts", 2)); exploration_depth = int(data.get("exploration_depth", 0)); daily_event = str(data.get("daily_event", "")); days_played = int(data.get("days_played", 0))
