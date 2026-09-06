class_name TimelineDirector
extends RefCounted

var enabled := false
var catalog: Dictionary = {}
var fired: Dictionary = {}
var memories: Dictionary = {}
var unlocked_recipes: Dictionary = {}
var weekly_choices: Array[Dictionary] = []
var active_weekly: Dictionary = {}
var completed_weeklies: Array[String] = []
var seasonal_choices: Array[Dictionary] = []
var active_project: Dictionary = {}
var project_delivered: Dictionary = {}
var completed_projects: Array[String] = []
var pending_choice: Dictionary = {}
var year_history: Array[Dictionary] = []
var last_year_review: Dictionary = {}
var festival_score := 0
var offered_week_key := ""
var offered_season_key := ""


func configure(scenario_id: String, path: String) -> Error:
	enabled = scenario_id == "medieval"
	if not enabled: return OK
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	catalog = parsed.duplicate(true)
	return OK


func begin_day(calendar: Variant, context: Dictionary) -> Array[Dictionary]:
	if not enabled: return []
	if bool(context.get("keep_built", false)):
		var week_key: String = "%d:%d:%d" % [calendar.year, calendar.season_index, calendar.week_of_season()]
		if week_key != offered_week_key and active_weekly.is_empty(): offered_week_key = week_key; _prepare_weekly_choices(calendar)
		var season_key: String = "%d:%d" % [calendar.year, calendar.season_index]
		if season_key != offered_season_key and active_project.is_empty(): offered_season_key = season_key; _prepare_seasonal_choices(calendar)
	var triggered: Array[Dictionary] = []
	for event: Dictionary in catalog.get("events", []):
		var event_id := str(event.get("id", ""))
		if event_id.is_empty() or (bool(event.get("once", true)) and fired.has(event_id)): continue
		if not _conditions_met(event.get("when", {}), calendar, context): continue
		fired[event_id] = calendar.absolute_day()
		for recipe_id: Variant in event.get("effects", {}).get("unlock_recipes", []): unlocked_recipes[str(recipe_id)] = true
		for flag: Variant in event.get("effects", {}).get("remember", []): memories[str(flag)] = true
		if not event.get("choices", []).is_empty(): pending_choice = event.duplicate(true)
		triggered.append(event.duplicate(true))
	return triggered


func _conditions_met(when: Dictionary, calendar: Variant, context: Dictionary) -> bool:
	var absolute: int = calendar.absolute_day()
	if absolute < int(when.get("earliest_day", 1)) or absolute > int(when.get("latest_day", 999999)): return false
	if when.has("absolute_day") and absolute != int(when.absolute_day): return false
	if when.has("season") and str(when.season) != calendar.season_name(): return false
	if when.has("season_index") and int(when.season_index) != calendar.season_index: return false
	if when.has("day") and int(when.day) != calendar.day: return false
	if when.has("week") and int(when.week) != calendar.week_of_season(): return false
	if when.has("weekday") and str(when.weekday) != calendar.weekday_name(): return false
	if bool(when.get("requires_keep", false)) and not bool(context.get("keep_built", false)): return false
	for flag: Variant in when.get("memories_all", []):
		if not memories.has(str(flag)): return false
	return true


func _prepare_weekly_choices(calendar: Variant) -> void:
	weekly_choices.clear()
	var templates: Array = catalog.get("weekly_ambitions", [])
	if templates.is_empty(): return
	var seed: int = calendar.absolute_day() + completed_weeklies.size() * 3
	for offset in range(mini(3, templates.size())):
		weekly_choices.append(templates[(seed + offset * 2) % templates.size()].duplicate(true))


func choose_weekly(index: int, context: Dictionary) -> bool:
	if index < 0 or index >= weekly_choices.size(): return false
	active_weekly = weekly_choices[index].duplicate(true)
	active_weekly["baseline"] = int(context.get(str(active_weekly.get("metric", "prosperity")), 0))
	weekly_choices.clear()
	return true


func weekly_progress(context: Dictionary) -> Vector2i:
	if active_weekly.is_empty(): return Vector2i.ZERO
	var current: int = int(context.get(str(active_weekly.metric), 0)) - int(active_weekly.get("baseline", 0))
	return Vector2i(maxi(0, current), int(active_weekly.target))


func update(context: Dictionary) -> Dictionary:
	if active_weekly.is_empty(): return {}
	var progress: Vector2i = weekly_progress(context)
	if progress.x < progress.y: return {}
	var result: Dictionary = active_weekly.duplicate(true)
	completed_weeklies.append(str(active_weekly.id)); memories["weekly_%s" % str(active_weekly.id)] = true
	active_weekly.clear()
	return result


func expire_weekly() -> Dictionary:
	if active_weekly.is_empty(): return {}
	var result: Dictionary = active_weekly.duplicate(true); result["failed"] = true; active_weekly.clear()
	return result


func _prepare_seasonal_choices(calendar: Variant) -> void:
	seasonal_choices.clear()
	for project: Dictionary in catalog.get("seasonal_projects", []):
		if str(project.get("season", "Any")) in ["Any", calendar.season_name()] and str(project.id) not in completed_projects:
			seasonal_choices.append(project.duplicate(true))
			if seasonal_choices.size() >= 3: break


func choose_project(index: int) -> bool:
	if index < 0 or index >= seasonal_choices.size(): return false
	active_project = seasonal_choices[index].duplicate(true); project_delivered.clear(); seasonal_choices.clear()
	return true


func contribute_project(inventory: Variant) -> Dictionary:
	if active_project.is_empty(): return {}
	var moved: Dictionary = {}
	for item_id: String in active_project.get("cost", {}):
		var remaining: int = int(active_project.cost[item_id]) - int(project_delivered.get(item_id, 0))
		var amount: int = mini(remaining, inventory.count(item_id))
		if amount > 0: inventory.remove(item_id, amount); project_delivered[item_id] = int(project_delivered.get(item_id, 0)) + amount; moved[item_id] = amount
	if project_complete():
		completed_projects.append(str(active_project.id)); memories["project_%s" % str(active_project.id)] = true
		var completed: Dictionary = active_project.duplicate(true); active_project.clear(); return {"moved":moved, "completed":completed}
	return {"moved":moved}


func project_complete() -> bool:
	if active_project.is_empty(): return false
	for item_id: String in active_project.get("cost", {}):
		if int(project_delivered.get(item_id, 0)) < int(active_project.cost[item_id]): return false
	return true


func project_progress_text() -> String:
	if active_project.is_empty(): return "No seasonal project chosen."
	var rows: Array[String] = []
	for item_id: String in active_project.get("cost", {}): rows.append("%s %d/%d" % [item_id.replace("_", " ").capitalize(), int(project_delivered.get(item_id, 0)), int(active_project.cost[item_id])])
	return "%s: %s" % [str(active_project.label), ", ".join(rows)]


func choose_event(index: int) -> Dictionary:
	if pending_choice.is_empty() or index < 0 or index >= pending_choice.get("choices", []).size(): return {}
	var choice: Dictionary = pending_choice.choices[index].duplicate(true)
	for flag: Variant in choice.get("remember", []): memories[str(flag)] = true
	pending_choice.clear()
	return choice


func recipe_unlocked(recipe_id: String) -> bool:
	var timed: Array = catalog.get("timed_recipes", [])
	return recipe_id not in timed or unlocked_recipes.has(recipe_id)


func make_year_review(calendar: Variant, context: Dictionary) -> Dictionary:
	var style: String = "The Hearthkeeper"
	if int(context.get("prosperity", 0)) > int(context.get("community", 0)) + 5: style = "The Silver Steward"
	elif int(context.get("beauty", 0)) > int(context.get("prosperity", 0)): style = "The Valley Gardener"
	elif int(context.get("exploration", 0)) >= 3: style = "The Ruin Seeker"
	last_year_review = {"year":calendar.year, "title":style, "weeklies":completed_weeklies.size(), "projects":completed_projects.size(), "festival":festival_score}
	year_history.append(last_year_review.duplicate(true)); memories["completed_year_%d" % calendar.year] = true
	return last_year_review


func snapshot() -> Dictionary:
	return {"fired":fired.duplicate(true),"memories":memories.duplicate(true),"unlocked_recipes":unlocked_recipes.duplicate(true),"weekly_choices":weekly_choices.duplicate(true),"active_weekly":active_weekly.duplicate(true),"completed_weeklies":completed_weeklies.duplicate(),"seasonal_choices":seasonal_choices.duplicate(true),"active_project":active_project.duplicate(true),"project_delivered":project_delivered.duplicate(true),"completed_projects":completed_projects.duplicate(),"pending_choice":pending_choice.duplicate(true),"year_history":year_history.duplicate(true),"last_year_review":last_year_review.duplicate(true),"festival_score":festival_score,"offered_week":offered_week_key,"offered_season":offered_season_key}


func restore(data: Dictionary) -> void:
	if data.is_empty(): return
	fired = data.get("fired", {}).duplicate(true); memories = data.get("memories", {}).duplicate(true); unlocked_recipes = data.get("unlocked_recipes", {}).duplicate(true)
	weekly_choices.assign(data.get("weekly_choices", [])); active_weekly = data.get("active_weekly", {}).duplicate(true); completed_weeklies.assign(data.get("completed_weeklies", []))
	seasonal_choices.assign(data.get("seasonal_choices", [])); active_project = data.get("active_project", {}).duplicate(true); project_delivered = data.get("project_delivered", {}).duplicate(true); completed_projects.assign(data.get("completed_projects", []))
	pending_choice = data.get("pending_choice", {}).duplicate(true); year_history.assign(data.get("year_history", [])); last_year_review = data.get("last_year_review", {}).duplicate(true); festival_score = int(data.get("festival_score", 0))
	offered_week_key = str(data.get("offered_week", "")); offered_season_key = str(data.get("offered_season", ""))
