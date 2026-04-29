extends RefCounted

const BACKGROUND_DEFS_PATH := "res://data/background_defs.json"
const FALLBACK_BACKGROUND_VARIANT := "LofiBG_01_Nomal_Day"


static func load_background_defs() -> Array:
	var file := FileAccess.open(BACKGROUND_DEFS_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var backgrounds = parsed.get("backgrounds", [])
	if typeof(backgrounds) != TYPE_ARRAY:
		return []
	return backgrounds


static func store_items(background_defs: Array, unlocked_content: Array, localizer) -> Array:
	var items := []
	for definition in background_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var content_id := str(definition.get("content_id", ""))
		var name_key := str(definition.get("display_name_key", content_id))
		items.append({
			"content_id": content_id,
			"name": localizer.translate(name_key) if localizer != null else name_key,
			"cost_focus_points": int(definition.get("cost_focus_points", 0)),
			"unlocked": is_unlocked(definition, unlocked_content),
			"default_unlocked": bool(definition.get("default_unlocked", false))
		})
	return items


static func purchase_background(content_id: String, background_defs: Array, unlocked_content: Array, currencies: Dictionary) -> Dictionary:
	var definition := find_by_content_id(background_defs, content_id)
	if definition.is_empty():
		return {"changed": false, "status": "missing"}
	if is_unlocked(definition, unlocked_content):
		return {"changed": false, "status": "already_unlocked"}
	var cost := int(definition.get("cost_focus_points", 0))
	if int(currencies.get("focus_points", 0)) < cost:
		return {"changed": false, "status": "insufficient", "cost_focus_points": cost}
	currencies.focus_points = int(currencies.get("focus_points", 0)) - cost
	unlocked_content.append({
		"content_id": content_id,
		"unlocked_at": Time.get_datetime_string_from_system(false, true)
	})
	return {"changed": true, "status": "purchased", "cost_focus_points": cost}


static func background_variant_for_context(context: Dictionary, background_defs: Array, unlocked_content: Array) -> String:
	var desired := _find_best_match(background_defs, context, str(context.get("mood", "normal")))
	if not desired.is_empty() and is_unlocked(desired, unlocked_content):
		return str(desired.get("spine_variant", FALLBACK_BACKGROUND_VARIANT))

	var normal_context := context.duplicate()
	normal_context.mood = "normal"
	var fallback := _find_best_match(background_defs, normal_context, "normal")
	if not fallback.is_empty() and is_unlocked(fallback, unlocked_content):
		return str(fallback.get("spine_variant", FALLBACK_BACKGROUND_VARIANT))

	return FALLBACK_BACKGROUND_VARIANT


static func find_by_content_id(background_defs: Array, content_id: String) -> Dictionary:
	for definition in background_defs:
		if typeof(definition) == TYPE_DICTIONARY and str(definition.get("content_id", "")) == content_id:
			return definition
	return {}


static func is_unlocked(definition: Dictionary, unlocked_content: Array) -> bool:
	if bool(definition.get("default_unlocked", false)):
		return true
	var content_id := str(definition.get("content_id", ""))
	for unlock in unlocked_content:
		if typeof(unlock) == TYPE_DICTIONARY and str(unlock.get("content_id", "")) == content_id:
			return true
		if typeof(unlock) == TYPE_STRING and str(unlock) == content_id:
			return true
	return false


static func _find_best_match(background_defs: Array, context: Dictionary, mood: String) -> Dictionary:
	var time := str(context.get("time", "day"))
	var weather := str(context.get("weather", "clear"))
	var loose_match := {}
	for definition in background_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var requirement = definition.get("context_requirement", {})
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		if str(requirement.get("mood", "")) != mood:
			continue
		if str(requirement.get("time", "")) != time:
			continue
		if str(requirement.get("weather", "clear")) == weather:
			return definition
		if loose_match.is_empty():
			loose_match = definition
	return loose_match
