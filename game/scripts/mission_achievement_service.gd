extends RefCounted

const ProgressionService = preload("res://scripts/progression_service.gd")

const MISSION_DEFS_PATH := "res://data/mission_defs.json"
const ACHIEVEMENT_DEFS_PATH := "res://data/achievement_defs.json"


static func load_mission_defs() -> Array:
	return _load_defs(MISSION_DEFS_PATH, "missions")


static func load_achievement_defs() -> Array:
	return _load_defs(ACHIEVEMENT_DEFS_PATH, "achievements")


static func refresh_daily_missions(
	mission_defs: Array,
	daily_missions: Array,
	stats: Dictionary,
	local_date: String
) -> Array:
	_reset_expired_missions(daily_missions, local_date)
	for definition in mission_defs:
		if typeof(definition) != TYPE_DICTIONARY or not bool(definition.get("is_active", true)):
			continue
		var mission_id := str(definition.get("mission_id", ""))
		if mission_id == "":
			continue
		var state := _find_state(daily_missions, "mission_id", mission_id)
		if state.is_empty():
			state = {
				"mission_id": mission_id,
				"local_date": local_date,
				"progress": 0,
				"target": int(definition.get("target", 1)),
				"status": "active",
				"claimed_at": ""
			}
			daily_missions.append(state)
		if str(state.get("status", "active")) == "claimed":
			continue
		state.progress = min(_metric_value(str(definition.get("metric", "")), stats), int(definition.get("target", 1)))
		state.target = int(definition.get("target", 1))
		state.status = "claimable" if int(state.progress) >= int(state.target) else "active"
	return daily_missions


static func refresh_achievements(
	achievement_defs: Array,
	user_achievements: Array,
	stats: Dictionary,
	currencies: Dictionary,
	level_progress: Dictionary,
	bond_progress: Dictionary,
	grant_rewards: bool = true
) -> Array:
	var unlocked := []
	for definition in achievement_defs:
		if typeof(definition) != TYPE_DICTIONARY or not bool(definition.get("is_active", true)):
			continue
		var achievement_id := str(definition.get("achievement_id", ""))
		if achievement_id == "":
			continue
		var state := _find_state(user_achievements, "achievement_id", achievement_id)
		if state.is_empty():
			state = {
				"achievement_id": achievement_id,
				"progress": 0,
				"target": int(definition.get("target", 1)),
				"status": "active",
				"unlocked_at": ""
			}
			user_achievements.append(state)
		if str(state.get("status", "active")) == "unlocked":
			continue
		state.progress = min(_metric_value(str(definition.get("metric", "")), stats), int(definition.get("target", 1)))
		state.target = int(definition.get("target", 1))
		if int(state.progress) >= int(state.target):
			state.status = "unlocked"
			state.unlocked_at = Time.get_datetime_string_from_system(false, true)
			if grant_rewards:
				_grant_rewards(definition, currencies, level_progress, bond_progress)
			unlocked.append(achievement_id)
	return unlocked


static func claim_mission(
	mission_id: String,
	mission_defs: Array,
	daily_missions: Array,
	currencies: Dictionary,
	level_progress: Dictionary,
	bond_progress: Dictionary
) -> Dictionary:
	var state := _find_state(daily_missions, "mission_id", mission_id)
	if state.is_empty() or str(state.get("status", "")) != "claimable":
		return {"changed": false, "status": "not_claimable"}
	var definition := _find_state(mission_defs, "mission_id", mission_id)
	if definition.is_empty():
		return {"changed": false, "status": "missing"}
	state.status = "claimed"
	state.claimed_at = Time.get_datetime_string_from_system(false, true)
	_grant_rewards(definition, currencies, level_progress, bond_progress)
	return {
		"changed": true,
		"status": "claimed",
		"focus_points": int(definition.get("reward_focus_points", 0)),
		"xp": int(definition.get("reward_xp", 0)),
		"bond": int(definition.get("reward_bond", 0))
	}


static func panel_items(definitions: Array, states: Array, id_key: String, localizer) -> Array:
	var items := []
	for definition in definitions:
		if typeof(definition) != TYPE_DICTIONARY or not bool(definition.get("is_active", true)):
			continue
		var item_id := str(definition.get(id_key, ""))
		var state := _find_state(states, id_key, item_id)
		var target := int(definition.get("target", 1))
		var progress := int(state.get("progress", 0)) if not state.is_empty() else 0
		items.append({
			"id": item_id,
			"name": _tr(localizer, str(definition.get("display_name_key", item_id))),
			"progress": progress,
			"target": target,
			"status": str(state.get("status", "active")) if not state.is_empty() else "active",
			"reward_focus_points": int(definition.get("reward_focus_points", 0)),
			"reward_xp": int(definition.get("reward_xp", 0)),
			"reward_bond": int(definition.get("reward_bond", 0))
		})
	return items


static func stats_snapshot(daily_stats: Dictionary, sessions: Array, tasks: Array, unlocked_content: Array, level_progress: Dictionary, bond_progress: Dictionary) -> Dictionary:
	var completed := int(daily_stats.get("completed_sessions", 0))
	var partial := int(daily_stats.get("partial_sessions", 0))
	var focus_minutes := int(daily_stats.get("focus_minutes_completed", 0)) + int(daily_stats.get("focus_minutes_partial", 0))
	var tasks_completed := int(daily_stats.get("tasks_completed", 0))
	return {
		"completed_sessions": completed,
		"partial_sessions": partial,
		"focus_minutes_total": focus_minutes,
		"tasks_completed": tasks_completed,
		"session_count": sessions.size(),
		"task_count": tasks.size(),
		"unlocked_count": unlocked_content.size(),
		"focus_level": int(level_progress.get("focus_level", 1)),
		"bond_level": int(bond_progress.get("bond_level", 1))
	}


static func _load_defs(path: String, key: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var defs = parsed.get(key, [])
	if typeof(defs) != TYPE_ARRAY:
		return []
	return defs


static func _reset_expired_missions(daily_missions: Array, local_date: String) -> void:
	for state in daily_missions:
		if typeof(state) != TYPE_DICTIONARY:
			continue
		if str(state.get("local_date", "")) != local_date:
			state.local_date = local_date
			state.progress = 0
			state.status = "active"
			state.claimed_at = ""


static func _metric_value(metric: String, stats: Dictionary) -> int:
	return int(stats.get(metric, 0))


static func _find_state(items: Array, id_key: String, id_value: String) -> Dictionary:
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get(id_key, "")) == id_value:
			return item
	return {}


static func _grant_rewards(definition: Dictionary, currencies: Dictionary, level_progress: Dictionary, bond_progress: Dictionary) -> void:
	var focus_points := int(definition.get("reward_focus_points", 0))
	var xp := int(definition.get("reward_xp", 0))
	var bond := int(definition.get("reward_bond", 0))
	currencies.focus_points = int(currencies.get("focus_points", 0)) + focus_points
	if xp > 0:
		ProgressionService.add_xp(level_progress, xp)
	if bond > 0:
		currencies.bond_points_total = int(currencies.get("bond_points_total", 0)) + bond
		ProgressionService.add_bond(bond_progress, bond)


static func _tr(localizer, key: String) -> String:
	if localizer != null:
		return localizer.translate(key)
	return key
