extends SceneTree

const BACKGROUND_DEFS_PATH := "res://data/background_defs.json"
const MISSION_DEFS_PATH := "res://data/mission_defs.json"
const ACHIEVEMENT_DEFS_PATH := "res://data/achievement_defs.json"
const LOCALIZATION_PATH := "res://data/localization.csv"
const MUSIC_TRACK_DEFS_PATH := "res://data/music_track_defs.json"
const SPINE_ROOT := "res://assets/spine/backgrounds"
const LOCALIZATION_LANGUAGE_CODES := ["en", "zh_TW", "zh_CN", "ja", "ko", "fr", "de", "it", "ru", "es_ES", "pt_BR"]


func _init() -> void:
	var errors := []
	var background_defs := _load_background_defs(errors)
	var localization_keys := _load_localization_keys(errors)
	_validate_background_defs(background_defs, localization_keys, errors)
	_validate_goal_defs(MISSION_DEFS_PATH, "missions", "mission_id", localization_keys, errors)
	_validate_goal_defs(ACHIEVEMENT_DEFS_PATH, "achievements", "achievement_id", localization_keys, errors)
	_validate_music_track_defs(errors)

	if errors.is_empty():
		print("Content integrity passed.")
		quit(0)
		return

	for error in errors:
		push_error(str(error))
		print("Content integrity error: %s" % str(error))
	quit(1)


func _load_background_defs(errors: Array) -> Array:
	var file := FileAccess.open(BACKGROUND_DEFS_PATH, FileAccess.READ)
	if file == null:
		errors.append("Missing %s" % BACKGROUND_DEFS_PATH)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Invalid JSON dictionary in %s" % BACKGROUND_DEFS_PATH)
		return []
	var backgrounds = parsed.get("backgrounds", [])
	if typeof(backgrounds) != TYPE_ARRAY:
		errors.append("backgrounds must be an array in %s" % BACKGROUND_DEFS_PATH)
		return []
	return backgrounds


func _load_localization_keys(errors: Array) -> Dictionary:
	var keys := {}
	var file := FileAccess.open(LOCALIZATION_PATH, FileAccess.READ)
	if file == null:
		errors.append("Missing %s" % LOCALIZATION_PATH)
		return keys
	if file.eof_reached():
		errors.append("Empty %s" % LOCALIZATION_PATH)
		return keys
	var header := file.get_csv_line()
	var columns := _csv_columns(header)
	_validate_localization_columns(columns, errors)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 0 and str(row[0]) != "":
			var key := str(row[0])
			keys[key] = true
			_validate_localization_row(key, row, columns, errors)
	return keys


func _csv_columns(header: PackedStringArray) -> Dictionary:
	var columns := {}
	for index in header.size():
		columns[str(header[index])] = index
	return columns


func _validate_localization_columns(columns: Dictionary, errors: Array) -> void:
	for language_code in LOCALIZATION_LANGUAGE_CODES:
		if not columns.has(language_code):
			errors.append("Localization is missing %s column." % language_code)


func _validate_localization_row(key: String, row: PackedStringArray, columns: Dictionary, errors: Array) -> void:
	if not columns.has("en"):
		return
	var english_index := int(columns["en"])
	if row.size() <= english_index:
		errors.append("%s is missing English localization text." % key)
		return
	var expected := _placeholder_set(str(row[english_index]))
	for language_code in LOCALIZATION_LANGUAGE_CODES:
		if not columns.has(language_code):
			continue
		var index := int(columns[language_code])
		if row.size() <= index or str(row[index]) == "":
			errors.append("%s is missing %s localization text." % [key, language_code])
			continue
		var actual := _placeholder_set(str(row[index]))
		if not _same_string_array(expected, actual):
			errors.append("%s %s placeholders %s do not match English placeholders %s." % [
				key,
				language_code,
				str(actual),
				str(expected)
			])


func _placeholder_set(text: String) -> Array:
	var regex := RegEx.new()
	regex.compile("\\{[^}]+\\}")
	var placeholders := {}
	for result in regex.search_all(text):
		placeholders[result.get_string()] = true
	var values := placeholders.keys()
	values.sort()
	return values


func _same_string_array(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if str(left[index]) != str(right[index]):
			return false
	return true


func _validate_background_defs(background_defs: Array, localization_keys: Dictionary, errors: Array) -> void:
	var seen_ids := {}
	for definition in background_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			errors.append("Background definition must be a dictionary.")
			continue

		var content_id := str(definition.get("content_id", ""))
		if content_id == "":
			errors.append("Background definition is missing content_id.")
			continue
		if seen_ids.has(content_id):
			errors.append("Duplicate background content_id: %s" % content_id)
		seen_ids[content_id] = true

		var display_name_key := str(definition.get("display_name_key", ""))
		if display_name_key == "":
			errors.append("%s is missing display_name_key." % content_id)
		elif not localization_keys.has(display_name_key):
			errors.append("%s uses missing localization key %s." % [content_id, display_name_key])

		var spine_variant := str(definition.get("spine_variant", ""))
		if spine_variant == "":
			errors.append("%s is missing spine_variant." % content_id)
		else:
			_validate_spine_variant(content_id, spine_variant, errors)

		var default_unlocked := bool(definition.get("default_unlocked", false))
		var cost := int(definition.get("cost_focus_points", 0))
		if not default_unlocked and cost <= 0:
			errors.append("%s is purchasable but has non-positive cost_focus_points." % content_id)


func _validate_spine_variant(content_id: String, spine_variant: String, errors: Array) -> void:
	for extension in ["skel", "atlas", "png"]:
		var path := "%s/%s/%s.%s" % [SPINE_ROOT, spine_variant, spine_variant, extension]
		if not FileAccess.file_exists(path):
			errors.append("%s references missing Spine asset %s." % [content_id, path])


func _validate_music_track_defs(errors: Array) -> void:
	var file := FileAccess.open(MUSIC_TRACK_DEFS_PATH, FileAccess.READ)
	if file == null:
		errors.append("Missing %s" % MUSIC_TRACK_DEFS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Invalid JSON dictionary in %s" % MUSIC_TRACK_DEFS_PATH)
		return
	var tracks = parsed.get("tracks", [])
	if typeof(tracks) != TYPE_ARRAY:
		errors.append("tracks must be an array in %s" % MUSIC_TRACK_DEFS_PATH)
		return
	var seen_paths := {}
	for track in tracks:
		if typeof(track) != TYPE_DICTIONARY:
			errors.append("Music track definition must be a dictionary.")
			continue
		var path := str(track.get("path", ""))
		if path == "":
			errors.append("Music track is missing path.")
			continue
		if seen_paths.has(path):
			errors.append("Duplicate music track path: %s" % path)
		seen_paths[path] = true
		if bool(track.get("enabled", true)) and not FileAccess.file_exists(path):
			errors.append("Music track references missing file %s." % path)
		if str(track.get("display_name", "")) == "":
			errors.append("Music track %s is missing display_name." % path)


func _validate_goal_defs(path: String, root_key: String, id_key: String, localization_keys: Dictionary, errors: Array) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Missing %s" % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Invalid JSON dictionary in %s" % path)
		return
	var defs = parsed.get(root_key, [])
	if typeof(defs) != TYPE_ARRAY:
		errors.append("%s must be an array in %s" % [root_key, path])
		return
	var seen_ids := {}
	for definition in defs:
		if typeof(definition) != TYPE_DICTIONARY:
			errors.append("%s entry must be a dictionary." % root_key)
			continue
		var item_id := str(definition.get(id_key, ""))
		if item_id == "":
			errors.append("%s entry is missing %s." % [root_key, id_key])
			continue
		if seen_ids.has(item_id):
			errors.append("Duplicate %s: %s" % [id_key, item_id])
		seen_ids[item_id] = true
		var key := str(definition.get("display_name_key", ""))
		if key == "" or not localization_keys.has(key):
			errors.append("%s uses missing localization key %s." % [item_id, key])
		if str(definition.get("metric", "")) == "":
			errors.append("%s is missing metric." % item_id)
		if int(definition.get("target", 0)) <= 0:
			errors.append("%s has non-positive target." % item_id)
