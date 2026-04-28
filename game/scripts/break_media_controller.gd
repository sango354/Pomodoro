extends Node

signal playback_failed(path: String)

const SUPPORTED_EXTENSIONS := ["ogv", "mp4"]

var video_player: VideoStreamPlayer
var break_media_enabled := false
var break_media_path := ""


func setup(parent: Control, enabled: bool, path: String) -> void:
	break_media_enabled = enabled
	break_media_path = path
	_build_video_player(parent)


func set_enabled(enabled: bool) -> void:
	break_media_enabled = enabled
	if not break_media_enabled:
		stop_break_media()


func set_media_path(path: String) -> void:
	break_media_path = path


func play_break_media() -> bool:
	if not break_media_enabled or break_media_path == "":
		return false
	if video_player == null:
		return false
	var stream = _load_video_stream(break_media_path)
	if stream == null:
		stop_break_media()
		playback_failed.emit(break_media_path)
		return false
	video_player.stream = stream
	video_player.visible = true
	if video_player.has_method("set_stream_position"):
		video_player.set_stream_position(0.0)
	video_player.play()
	call_deferred("_verify_playback_started", break_media_path)
	return true


func stop_break_media() -> void:
	if video_player == null:
		return
	video_player.stop()
	video_player.visible = false


func is_playing() -> bool:
	return video_player != null and video_player.visible and video_player.is_playing()


func _build_video_player(parent: Control) -> void:
	video_player = VideoStreamPlayer.new()
	video_player.name = "BreakMediaPlayer"
	video_player.visible = false
	video_player.z_index = 80
	video_player.expand = true
	video_player.anchor_left = 0.5
	video_player.anchor_top = 0.5
	video_player.anchor_right = 0.5
	video_player.anchor_bottom = 0.5
	video_player.offset_left = -260
	video_player.offset_top = -156
	video_player.offset_right = 260
	video_player.offset_bottom = 156
	video_player.finished.connect(_on_video_finished)
	parent.add_child(video_player)


func _load_video_stream(path: String):
	var ext := path.get_extension().to_lower()
	if not SUPPORTED_EXTENSIONS.has(ext):
		return null
	var resolved_path := _resolve_media_path(path)
	if resolved_path == "":
		return null
	ext = resolved_path.get_extension().to_lower()
	var stream = load(resolved_path) if ResourceLoader.exists(resolved_path) else null
	if stream != null:
		return stream
	if ext == "mp4":
		return _load_ogv_stream(_sidecar_ogv_path(resolved_path))
	return _load_ogv_stream(resolved_path)


func _load_ogv_stream(path: String):
	if path.get_extension().to_lower() != "ogv" or not _file_exists(path):
		return null
	if not ClassDB.class_exists("VideoStreamTheora"):
		return null
	var stream = VideoStreamTheora.new()
	stream.set("file", _media_file_path(path))
	return stream


func _on_video_finished() -> void:
	stop_break_media()


func _verify_playback_started(path: String) -> void:
	await get_tree().create_timer(0.25).timeout
	if video_player == null or not video_player.visible:
		return
	if video_player.stream == null or video_player.is_playing():
		return
	stop_break_media()
	playback_failed.emit(path)


func _resolve_media_path(path: String) -> String:
	if ResourceLoader.exists(path) or _file_exists(path):
		return path
	if path == "res://assets/videos/break/default.ogv":
		var migrated_path := "res://assets/videos/break/video.mp4"
		if ResourceLoader.exists(migrated_path) or _file_exists(migrated_path):
			return migrated_path
	return ""


func _file_exists(path: String) -> bool:
	if FileAccess.file_exists(path):
		return true
	if path.begins_with("res://"):
		return FileAccess.file_exists(ProjectSettings.globalize_path(path))
	return false


func _media_file_path(path: String) -> String:
	return path


func _sidecar_ogv_path(path: String) -> String:
	return "%s.ogv" % path.trim_suffix(".%s" % path.get_extension())
