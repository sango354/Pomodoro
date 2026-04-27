extends RefCounted

const DIALOGUE_PATH := "res://data/dialogue_defs.json"


static func load_break_dialogues() -> Array:
	var parsed := _load_dialogue_payload()
	if parsed.has("break_interaction") and typeof(parsed.break_interaction) == TYPE_ARRAY:
		return parsed.break_interaction
	return [
		{
			"dialogue_id": "break_fallback",
			"text_key": "dialogue.break_fallback",
			"text": "Take a short break. I will be here for the next round.",
			"bond_requirement": 0,
			"context_requirement": "any"
		}
	]


static func break_dialogue_text(index: int) -> String:
	var dialogues := load_break_dialogues()
	if dialogues.is_empty():
		return ""
	var dialogue = dialogues[index % dialogues.size()]
	return str(dialogue.get("text", ""))


static func break_dialogue_key(index: int) -> String:
	var dialogues := load_break_dialogues()
	if dialogues.is_empty():
		return ""
	var dialogue = dialogues[index % dialogues.size()]
	return str(dialogue.get("text_key", ""))


static func _load_dialogue_payload() -> Dictionary:
	if not FileAccess.file_exists(DIALOGUE_PATH):
		return {}
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
