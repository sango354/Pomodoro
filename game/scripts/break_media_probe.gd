extends Node

const BREAK_MEDIA_PATH := "res://assets/videos/break/video.mp4"


func _ready() -> void:
	var stream = ResourceLoader.load(BREAK_MEDIA_PATH) if ResourceLoader.exists(BREAK_MEDIA_PATH) else null
	var exists := ResourceLoader.exists(BREAK_MEDIA_PATH) or FileAccess.file_exists(BREAK_MEDIA_PATH)
	var global_path := ProjectSettings.globalize_path(BREAK_MEDIA_PATH)
	exists = exists or FileAccess.file_exists(global_path)
	if stream == null and BREAK_MEDIA_PATH.get_extension().to_lower() == "ogv" and exists:
		stream = VideoStreamTheora.new()
		stream.set("file", global_path)
	if stream == null and BREAK_MEDIA_PATH.get_extension().to_lower() == "mp4":
		var sidecar_path := _sidecar_ogv_path(BREAK_MEDIA_PATH)
		var sidecar_global_path := ProjectSettings.globalize_path(sidecar_path)
		if FileAccess.file_exists(sidecar_global_path):
			stream = VideoStreamTheora.new()
			stream.set("file", sidecar_global_path)
	print("Break media path exists: %s" % exists)
	print("Break media loaded: %s" % (stream != null))
	if stream != null:
		print("Break media class: %s" % stream.get_class())
	get_tree().quit(0 if stream != null else 1)


func _sidecar_ogv_path(path: String) -> String:
	return "%s.ogv" % path.trim_suffix(".%s" % path.get_extension())
