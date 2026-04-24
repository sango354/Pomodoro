extends Node

const SAVE_PATH := "user://save.json"
const ASSET_ROOT := "res://assets/spine/backgrounds"
const MUSIC_ROOT := "res://assets/music"
const TARGET_VIEWPORT_SIZE := Vector2(1152, 648)
const TASK_PANEL_WIDTH := 430
const TASK_ITEM_WIDTH := 258
const TIMER_RAIL_WIDTH := 190
const SETTINGS_PANEL_WIDTH := 300
const MIN_REWARDABLE_SESSION_SEC := 300
const BASE_FOCUS_POINTS := 20
const BASE_BOND := 10
const BASE_XP := 30
const TASK_BONUS_FOCUS_POINTS := 8
const TASK_BONUS_XP := 10

var app_state := "idle"
var session_mode := "focus"
var result_dismissed := false
var planned_duration_sec := 25 * 60
var elapsed_sec := 0.0
var pause_elapsed_sec := 0.0
var session_started_at := ""
var active_task_id := ""
var selected_context := {
	"mood": "normal",
	"time": "day",
	"weather": "clear"
}

var tasks: Array = []
var sessions: Array = []
var currencies := {
	"focus_points": 0,
	"bond_points_total": 0
}
var level_progress := {
	"focus_level": 1,
	"focus_xp": 0,
	"focus_xp_lifetime": 0
}
var bond_progress := {
	"character_id": "companion_01",
	"bond_level": 1,
	"bond_points_current": 0,
	"bond_points_lifetime": 0
}
var daily_stats := {
	"focus_minutes_completed": 0,
	"focus_minutes_partial": 0,
	"completed_sessions": 0,
	"partial_sessions": 0,
	"tasks_completed": 0
}

var spine_sprite: Node = null
var current_spine_variant := ""

var root_2d: Node2D
var ui_layer: CanvasLayer
var app_container: Control
var timer_label: Label
var break_time_label: Label
var phase_label: Label
var task_label: Label
var message_label: Label
var fp_label: Button
var level_label: Button
var bond_label: Button
var stats_label: Label
var progress_bar: ProgressBar
var duration_minutes := 25
var break_duration_minutes := 5
var duration_value_label: Label
var break_duration_value_label: Label
var primary_timer_button: Button
var reset_button: Button
var settings_button: Button
var settings_panel: PanelContainer
var task_list: VBoxContainer
var music_player: AudioStreamPlayer
var music_files: Array[String] = []
var current_music_index := -1
var music_loop := false
var music_list_panel: PanelContainer
var music_list: VBoxContainer
var track_label: Label
var play_button: Button
var loop_button: Button
var volume_slider: HSlider
var result_dismiss_layer: Button
var result_panel: PanelContainer
var result_title: Label
var result_rewards: Label
var mark_task_done_button: Button
var break_button: Button


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_spine_to_viewport)
	_load_save()
	_apply_time_context()
	_build_scene()
	_load_spine_background(_select_spine_variant())
	_refresh_all()


func _process(delta: float) -> void:
	if app_state != "running":
		return

	elapsed_sec += delta
	if elapsed_sec >= planned_duration_sec:
		elapsed_sec = planned_duration_sec
		_finish_session("completed")
		return

	_refresh_timer_ui()


func _build_scene() -> void:
	root_2d = Node2D.new()
	root_2d.name = "World"
	add_child(root_2d)

	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	app_container = Control.new()
	app_container.name = "App"
	app_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(app_container)

	var overlay := ColorRect.new()
	overlay.name = "ReadabilityOverlay"
	overlay.color = Color(0.04, 0.045, 0.05, 0.16)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	app_container.add_child(overlay)

	var margins := MarginContainer.new()
	margins.name = "LayoutMargins"
	margins.set_anchors_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_bottom", 22)
	app_container.add_child(margins)

	var layers := Control.new()
	layers.set_anchors_preset(Control.PRESET_FULL_RECT)
	margins.add_child(layers)

	_build_top_bar(layers)
	_build_task_panel(layers)
	_build_timer_rail(layers)
	_build_settings_panel(layers)
	_build_result_dismiss_layer(layers)
	_build_result_panel(layers)
	_build_bottom_bar(layers)
	_build_audio_player()
	_scan_music_files()


func _build_top_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.name = "TopBar"
	bar.anchor_left = 1.0
	bar.anchor_top = 0.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_left = -330
	bar.offset_top = 0
	bar.offset_right = 0
	bar.offset_bottom = 46
	bar.add_theme_stylebox_override("panel", _new_panel_style(0.42))
	parent.add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var focus_button := _new_icon_button("FP", "Focus Points")
	fp_label = focus_button
	row.add_child(focus_button)

	var level_button := _new_icon_button("LV", "Focus Level")
	level_label = level_button
	row.add_child(level_button)

	var bond_button := _new_icon_button("BD", "Bond")
	bond_label = bond_button
	row.add_child(bond_button)

	var unlocks := _new_icon_button("UL", "Unlocks")
	row.add_child(unlocks)

	var stats := _new_icon_button("ST", "Stats")
	stats.pressed.connect(_toggle_stats_message)
	row.add_child(stats)


func _build_timer_rail(parent: Control) -> void:
	var panel := _new_panel()
	panel.name = "TimerRail"
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -TIMER_RAIL_WIDTH
	panel.offset_top = 64
	panel.offset_right = 0
	panel.offset_bottom = 430
	panel.custom_minimum_size = Vector2(TIMER_RAIL_WIDTH, 0)
	parent.add_child(panel)
	var box := _panel_box(panel)

	phase_label = _new_muted_label("")
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(phase_label)

	timer_label = Label.new()
	timer_label.text = "25:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 42)
	box.add_child(timer_label)

	var break_label := _new_muted_label("Break 05:00")
	break_label.name = "BreakLabel"
	break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	break_time_label = break_label
	box.add_child(break_label)

	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	box.add_child(progress_bar)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	box.add_child(controls)

	primary_timer_button = Button.new()
	primary_timer_button.text = "Start"
	primary_timer_button.custom_minimum_size = Vector2(0, 36)
	primary_timer_button.pressed.connect(_on_primary_timer_pressed)
	controls.add_child(primary_timer_button)

	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(0, 36)
	reset_button.pressed.connect(_on_end_pressed)
	controls.add_child(reset_button)

	settings_button = Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(0, 34)
	settings_button.pressed.connect(_toggle_settings_panel)
	box.add_child(settings_button)

	task_label = _new_muted_label("")
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(task_label)
	message_label = _new_muted_label("")
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(message_label)


func _build_result_panel(parent: Control) -> void:
	result_panel = _new_panel()
	result_panel.anchor_left = 0.0
	result_panel.anchor_top = 1.0
	result_panel.anchor_right = 0.0
	result_panel.anchor_bottom = 1.0
	result_panel.offset_left = 0
	result_panel.offset_top = -260
	result_panel.offset_right = 430
	result_panel.offset_bottom = -82
	parent.add_child(result_panel)
	var box := _panel_box(result_panel)
	result_title = _new_title("Session Result")
	box.add_child(result_title)
	result_rewards = _new_muted_label("")
	box.add_child(result_rewards)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	mark_task_done_button = Button.new()
	mark_task_done_button.text = "Mark Task Done"
	mark_task_done_button.custom_minimum_size = Vector2(126, 30)
	mark_task_done_button.pressed.connect(_on_mark_bound_task_done)
	buttons.add_child(mark_task_done_button)

	break_button = Button.new()
	break_button.text = "Start Break"
	break_button.custom_minimum_size = Vector2(104, 30)
	break_button.pressed.connect(_on_break_pressed)
	buttons.add_child(break_button)


func _build_result_dismiss_layer(parent: Control) -> void:
	result_dismiss_layer = Button.new()
	result_dismiss_layer.name = "ResultDismissLayer"
	result_dismiss_layer.flat = true
	result_dismiss_layer.visible = false
	result_dismiss_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_dismiss_layer.text = ""
	result_dismiss_layer.focus_mode = Control.FOCUS_NONE
	result_dismiss_layer.pressed.connect(_dismiss_result_panel)
	parent.add_child(result_dismiss_layer)


func _build_task_panel(parent: Control) -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_top = 0.0
	box.anchor_right = 0.0
	box.anchor_bottom = 0.0
	box.offset_left = 0
	box.offset_top = 0
	box.offset_right = TASK_PANEL_WIDTH
	box.offset_bottom = 284
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	var title := _new_title("Tasks")
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)

	var add_button := Button.new()
	add_button.text = "+"
	add_button.tooltip_text = "Add task"
	add_button.custom_minimum_size = Vector2(34, 32)
	add_button.pressed.connect(_on_add_task_pressed)
	header.add_child(add_button)

	task_list = VBoxContainer.new()
	task_list.add_theme_constant_override("separation", 6)
	box.add_child(task_list)


func _build_settings_panel(parent: Control) -> void:
	settings_panel = _new_panel()
	settings_panel.name = "SettingsPanel"
	settings_panel.visible = false
	settings_panel.anchor_top = 0.0
	settings_panel.anchor_bottom = 0.0
	settings_panel.anchor_left = 0.0
	settings_panel.anchor_right = 0.0
	settings_panel.offset_left = 0
	settings_panel.offset_top = 292
	settings_panel.offset_right = SETTINGS_PANEL_WIDTH
	settings_panel.offset_bottom = 530
	parent.add_child(settings_panel)

	var box := _panel_box(settings_panel)
	box.add_child(_new_title("Timer Settings"))
	box.add_child(_new_muted_label("Focus duration"))
	_build_duration_adjuster(box, true)
	box.add_child(_new_muted_label("Break duration"))
	_build_duration_adjuster(box, false)

	var auto_label := _new_muted_label("Auto restart: off")
	box.add_child(auto_label)
	var alarm_label := _new_muted_label("Alarm: soft bell")
	box.add_child(alarm_label)


func _build_duration_adjuster(parent: VBoxContainer, focus: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(42, 32)
	minus_button.pressed.connect(_adjust_duration_minutes.bind(-5) if focus else _adjust_break_duration_minutes.bind(-5))
	row.add_child(minus_button)

	var value_label := _new_muted_label("")
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(92, 32)
	row.add_child(value_label)
	if focus:
		duration_value_label = value_label
	else:
		break_duration_value_label = value_label

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(42, 32)
	plus_button.pressed.connect(_adjust_duration_minutes.bind(5) if focus else _adjust_break_duration_minutes.bind(5))
	row.add_child(plus_button)

	if focus:
		for minutes in [15, 25, 45]:
			var preset := Button.new()
			preset.text = "%d" % minutes
			preset.custom_minimum_size = Vector2(46, 32)
			preset.pressed.connect(_set_duration_minutes.bind(minutes))
			row.add_child(preset)


func _build_bottom_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.anchor_left = 0.0
	bar.anchor_top = 1.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 0
	bar.offset_top = -50
	bar.offset_right = 0
	bar.offset_bottom = 0
	bar.add_theme_stylebox_override("panel", _new_panel_style(0.64))
	parent.add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var menu_button := Button.new()
	menu_button.text = "List"
	menu_button.custom_minimum_size = Vector2(58, 32)
	menu_button.pressed.connect(_toggle_music_list)
	row.add_child(menu_button)

	track_label = _new_muted_label("No music loaded")
	track_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(track_label)

	var prev_button := Button.new()
	prev_button.text = "Prev"
	prev_button.custom_minimum_size = Vector2(58, 32)
	prev_button.pressed.connect(_play_previous_music)
	row.add_child(prev_button)

	play_button = Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(58, 32)
	play_button.pressed.connect(_toggle_music_playback)
	row.add_child(play_button)

	var next_button := Button.new()
	next_button.text = "Next"
	next_button.custom_minimum_size = Vector2(58, 32)
	next_button.pressed.connect(_play_next_music)
	row.add_child(next_button)

	loop_button = Button.new()
	loop_button.text = "Loop Off"
	loop_button.custom_minimum_size = Vector2(82, 32)
	loop_button.pressed.connect(_toggle_music_loop)
	row.add_child(loop_button)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.01
	volume_slider.value = 0.7
	volume_slider.custom_minimum_size = Vector2(130, 32)
	volume_slider.value_changed.connect(_on_volume_changed)
	row.add_child(volume_slider)

	var ambience := Button.new()
	ambience.text = "Ambience"
	ambience.custom_minimum_size = Vector2(100, 32)
	row.add_child(ambience)

	stats_label = _new_muted_label("")
	stats_label.visible = false
	row.add_child(stats_label)

	music_list_panel = _new_panel()
	music_list_panel.visible = false
	music_list_panel.anchor_left = 0.0
	music_list_panel.anchor_top = 1.0
	music_list_panel.anchor_right = 0.0
	music_list_panel.anchor_bottom = 1.0
	music_list_panel.offset_left = 0
	music_list_panel.offset_top = -332
	music_list_panel.offset_right = 430
	music_list_panel.offset_bottom = -58
	parent.add_child(music_list_panel)
	var list_box := _panel_box(music_list_panel)
	list_box.add_child(_new_title("Music"))
	music_list = VBoxContainer.new()
	music_list.add_theme_constant_override("separation", 6)
	list_box.add_child(music_list)


func _new_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _new_panel_style(0.62))
	return panel


func _new_panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.068, alpha)
	style.border_color = Color(1, 1, 1, 0.14)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _panel_box(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box


func _new_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	return label


func _new_icon_button(text: String, tip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tip
	button.custom_minimum_size = Vector2(42, 32)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _new_muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9, 0.92))
	return label


func _build_audio_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = linear_to_db(float(volume_slider.value))
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)


func _scan_music_files() -> void:
	music_files.clear()
	var dir := DirAccess.open(MUSIC_ROOT)
	if dir != null:
		for file_name in dir.get_files():
			var ext := file_name.get_extension().to_lower()
			if ext == "ogg" or ext == "mp3" or ext == "wav":
				music_files.append("%s/%s" % [MUSIC_ROOT, file_name])
	music_files.sort()
	_refresh_music_list()
	if music_files.is_empty():
		track_label.text = "Add .ogg, .mp3, or .wav files to res://assets/music"
	else:
		current_music_index = 0
		_update_track_label()


func _refresh_music_list() -> void:
	if music_list == null:
		return
	for child in music_list.get_children():
		child.queue_free()
	if music_files.is_empty():
		music_list.add_child(_new_muted_label("No music files found."))
		return
	for i in range(music_files.size()):
		var button := Button.new()
		button.text = _music_display_name(music_files[i])
		button.tooltip_text = music_files[i]
		button.custom_minimum_size = Vector2(0, 32)
		button.pressed.connect(_select_music.bind(i))
		music_list.add_child(button)


func _toggle_music_list() -> void:
	music_list_panel.visible = not music_list_panel.visible


func _select_music(index: int) -> void:
	if index < 0 or index >= music_files.size():
		return
	current_music_index = index
	_play_current_music()
	music_list_panel.visible = false


func _toggle_music_playback() -> void:
	if music_files.is_empty():
		return
	if current_music_index < 0:
		current_music_index = 0
	if music_player.playing:
		music_player.stream_paused = true
		play_button.text = "Play"
	elif music_player.stream != null and music_player.stream_paused:
		music_player.stream_paused = false
		play_button.text = "Pause"
	else:
		_play_current_music()


func _play_current_music() -> void:
	if current_music_index < 0 or current_music_index >= music_files.size():
		return
	var music_path := music_files[current_music_index]
	var stream := load(music_path)
	if stream == null:
		stream = _load_music_from_file(music_path)
	if stream == null:
		track_label.text = "Could not load: %s" % _music_display_name(music_path)
		return
	music_player.stream = stream
	music_player.stream_paused = false
	music_player.play()
	play_button.text = "Pause"
	_update_track_label()


func _load_music_from_file(path: String):
	var ext := path.get_extension().to_lower()
	if ext == "mp3" and ClassDB.class_exists("AudioStreamMP3"):
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			return null
		var stream := AudioStreamMP3.new()
		stream.data = bytes
		return stream
	return null


func _play_previous_music() -> void:
	if music_files.is_empty():
		return
	current_music_index = (current_music_index - 1 + music_files.size()) % music_files.size()
	_play_current_music()


func _play_next_music() -> void:
	if music_files.is_empty():
		return
	current_music_index = (current_music_index + 1) % music_files.size()
	_play_current_music()


func _toggle_music_loop() -> void:
	music_loop = not music_loop
	loop_button.text = "Loop On" if music_loop else "Loop Off"


func _on_volume_changed(value: float) -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(max(value, 0.001))


func _on_music_finished() -> void:
	if music_loop:
		_play_current_music()
	else:
		_play_next_music()


func _update_track_label() -> void:
	if current_music_index >= 0 and current_music_index < music_files.size():
		track_label.text = _music_display_name(music_files[current_music_index])


func _music_display_name(path: String) -> String:
	return path.get_file().get_basename()


func _on_primary_timer_pressed() -> void:
	if app_state == "paused":
		app_state = "running"
		message_label.text = "Back in focus"
		_refresh_all()
		return
	if app_state == "running":
		app_state = "paused"
		message_label.text = "Paused"
		_refresh_all()
		return
	_start_focus_session()


func _start_focus_session() -> void:
	if app_state == "running":
		return
	session_mode = "focus"
	planned_duration_sec = duration_minutes * 60
	elapsed_sec = 0.0
	pause_elapsed_sec = 0.0
	session_started_at = Time.get_datetime_string_from_system(false, true)
	active_task_id = _selected_task_id()
	if active_task_id != "":
		_set_task_status(active_task_id, "in_progress")
	app_state = "running"
	message_label.text = "Stay with it."
	_load_spine_background(_select_spine_variant())
	_refresh_all()


func _on_end_pressed() -> void:
	if app_state == "running" or app_state == "paused":
		var ratio := elapsed_sec / float(max(planned_duration_sec, 1))
		if ratio >= 0.3:
			_finish_session("partial")
		else:
			_finish_session("abandoned")


func _on_break_pressed() -> void:
	session_mode = "short_break"
	planned_duration_sec = break_duration_minutes * 60
	elapsed_sec = 0.0
	active_task_id = ""
	app_state = "running"
	message_label.text = "Take a short break."
	_dismiss_result_panel()
	_refresh_all()


func _finish_session(status: String) -> void:
	var actual_sec := int(round(elapsed_sec))
	var rewards := _grant_rewards(status, actual_sec)
	var session := {
		"session_id": "session_%s" % Time.get_unix_time_from_system(),
		"user_id": "local_user",
		"mode": session_mode,
		"planned_duration_sec": planned_duration_sec,
		"actual_duration_sec": actual_sec,
		"status": status,
		"started_at": session_started_at,
		"ended_at": Time.get_datetime_string_from_system(false, true),
		"linked_task_id": active_task_id,
		"context_id": _context_id(),
		"reward_granted_at": Time.get_datetime_string_from_system(false, true) if rewards.rewardable else ""
	}
	sessions.append(session)
	_update_stats(status, actual_sec)
	app_state = status
	result_dismissed = false
	selected_context.mood = "good" if status == "completed" else "troubled"
	_load_spine_background(_select_spine_variant())
	_save_game()
	result_title.text = _status_title(status)
	result_rewards.text = rewards.summary
	message_label.text = "Session logged."
	_refresh_all()


func _grant_rewards(status: String, actual_sec: int) -> Dictionary:
	var rewardable := session_mode == "focus" and actual_sec >= MIN_REWARDABLE_SESSION_SEC and status != "abandoned"
	if not rewardable:
		return {
			"rewardable": false,
			"summary": "No reward. Session was below the reward threshold."
		}

	var ratio := 1.0
	if status == "partial":
		ratio = clamp(actual_sec / float(planned_duration_sec), 0.3, 0.99)

	var focus_points := int(round(BASE_FOCUS_POINTS * ratio))
	var bond := int(round(BASE_BOND * ratio))
	var xp := int(round(BASE_XP * ratio))

	currencies.focus_points += focus_points
	currencies.bond_points_total += bond
	_add_xp(xp)
	_add_bond(bond)

	return {
		"rewardable": true,
		"summary": "+%d Focus Points  +%d XP  +%d Bond" % [focus_points, xp, bond]
	}


func _add_xp(amount: int) -> void:
	level_progress.focus_xp += amount
	level_progress.focus_xp_lifetime += amount
	var required := _xp_required_for_next_level()
	while level_progress.focus_xp >= required:
		level_progress.focus_xp -= required
		level_progress.focus_level += 1
		required = _xp_required_for_next_level()


func _add_bond(amount: int) -> void:
	bond_progress.bond_points_current += amount
	bond_progress.bond_points_lifetime += amount
	bond_progress.last_interaction_at = Time.get_datetime_string_from_system(false, true)
	var required := _bond_required_for_next_level()
	while bond_progress.bond_points_current >= required:
		bond_progress.bond_points_current -= required
		bond_progress.bond_level += 1
		required = _bond_required_for_next_level()


func _xp_required_for_next_level() -> int:
	return 80 + (int(level_progress.focus_level) - 1) * 30


func _bond_required_for_next_level() -> int:
	return 60 + (int(bond_progress.bond_level) - 1) * 25


func _on_add_task_pressed() -> void:
	_create_task("Type Here")


func _on_task_submitted(text: String) -> void:
	_create_task(text)


func _create_task(title: String) -> void:
	title = title.strip_edges()
	if title == "":
		return
	var task := {
		"task_id": "task_%s" % Time.get_unix_time_from_system(),
		"user_id": "local_user",
		"title": title,
		"description": "",
		"status": "todo",
		"sort_order": tasks.size(),
		"created_at": Time.get_datetime_string_from_system(false, true),
		"updated_at": Time.get_datetime_string_from_system(false, true),
		"completed_at": ""
	}
	tasks.append(task)
	_save_game()
	_refresh_all()


func _on_mark_bound_task_done() -> void:
	if active_task_id == "":
		return
	if _set_task_status(active_task_id, "done"):
		currencies.focus_points += TASK_BONUS_FOCUS_POINTS
		_add_xp(TASK_BONUS_XP)
		daily_stats.tasks_completed += 1
		result_rewards.text += "\nTask bonus: +%d Focus Points  +%d XP" % [TASK_BONUS_FOCUS_POINTS, TASK_BONUS_XP]
		_save_game()
		_refresh_all()


func _set_task_status(task_id: String, status: String) -> bool:
	for task in tasks:
		if task.task_id == task_id:
			task.status = status
			task.updated_at = Time.get_datetime_string_from_system(false, true)
			if status == "done":
				task.completed_at = Time.get_datetime_string_from_system(false, true)
			return true
	return false


func _archive_task(task_id: String) -> void:
	if _set_task_status(task_id, "archived"):
		_save_game()
		_refresh_all()


func _complete_task(task_id: String) -> void:
	if _set_task_status(task_id, "done"):
		daily_stats.tasks_completed += 1
		_save_game()
		_refresh_all()


func _selected_task_id() -> String:
	for task in tasks:
		if task.status == "todo" or task.status == "in_progress":
			return str(task.task_id)
	return ""


func _refresh_all() -> void:
	_refresh_timer_ui()
	_refresh_tasks_ui()
	_refresh_progress_ui()
	_refresh_controls()


func _refresh_timer_ui() -> void:
	var remaining: int = max(planned_duration_sec - int(elapsed_sec), 0)
	timer_label.text = _format_time(remaining)
	progress_bar.value = 100.0 * elapsed_sec / float(max(planned_duration_sec, 1))
	if duration_value_label != null:
		duration_value_label.text = "%d min" % duration_minutes
	if break_duration_value_label != null:
		break_duration_value_label.text = "%d min" % break_duration_minutes
	if break_time_label != null:
		break_time_label.text = "Break %s" % _format_time(break_duration_minutes * 60)
	var mode_text := "Focus" if session_mode == "focus" else "Short Break"
	phase_label.text = "%s - %s" % [mode_text, app_state.capitalize()]
	task_label.text = "Task: %s" % _task_title(active_task_id) if active_task_id != "" else "Task: none"


func _refresh_controls() -> void:
	var can_configure := app_state != "running" and app_state != "paused"
	primary_timer_button.disabled = false
	if app_state == "running":
		primary_timer_button.text = "Pause"
	elif app_state == "paused":
		primary_timer_button.text = "Resume"
	else:
		primary_timer_button.text = "Start"
	reset_button.disabled = app_state != "running" and app_state != "paused"
	var show_result := app_state == "completed" or app_state == "partial" or app_state == "abandoned"
	show_result = show_result and not result_dismissed
	result_panel.visible = show_result
	result_dismiss_layer.visible = show_result
	mark_task_done_button.disabled = active_task_id == "" or _task_status(active_task_id) == "done"
	break_button.disabled = app_state == "abandoned"


func _dismiss_result_panel() -> void:
	result_dismissed = true
	if result_panel != null:
		result_panel.visible = false
	if result_dismiss_layer != null:
		result_dismiss_layer.visible = false


func _set_duration_minutes(minutes: int) -> void:
	if app_state == "running" or app_state == "paused":
		return
	duration_minutes = clamp(minutes, 1, 180)
	planned_duration_sec = duration_minutes * 60
	_refresh_timer_ui()


func _adjust_duration_minutes(delta_minutes: int) -> void:
	_set_duration_minutes(duration_minutes + delta_minutes)


func _adjust_break_duration_minutes(delta_minutes: int) -> void:
	if app_state == "running" or app_state == "paused":
		return
	break_duration_minutes = clamp(break_duration_minutes + delta_minutes, 1, 60)
	_refresh_timer_ui()


func _toggle_settings_panel() -> void:
	settings_panel.visible = not settings_panel.visible


func _toggle_stats_message() -> void:
	stats_label.visible = not stats_label.visible


func _refresh_tasks_ui() -> void:
	for child in task_list.get_children():
		child.queue_free()

	var shown := 0
	for task in tasks:
		if task.status == "archived":
			continue
		if shown >= 5:
			break
		shown += 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.custom_minimum_size = Vector2(TASK_ITEM_WIDTH + 64, 0)
		task_list.add_child(row)

		var checkbox := CheckBox.new()
		checkbox.button_pressed = task.status == "done"
		checkbox.disabled = task.status == "done"
		checkbox.toggled.connect(_on_task_checkbox_toggled.bind(task.task_id))
		row.add_child(checkbox)

		var title_panel := PanelContainer.new()
		title_panel.custom_minimum_size = Vector2(TASK_ITEM_WIDTH, 0)
		title_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_panel.add_theme_stylebox_override("panel", _new_panel_style(0.72))
		row.add_child(title_panel)

		var title_margin := MarginContainer.new()
		title_margin.add_theme_constant_override("margin_left", 10)
		title_margin.add_theme_constant_override("margin_right", 10)
		title_margin.add_theme_constant_override("margin_top", 4)
		title_margin.add_theme_constant_override("margin_bottom", 4)
		title_panel.add_child(title_margin)

		var title_edit := LineEdit.new()
		var full_title := str(task.get("title", "Untitled"))
		title_edit.text = _task_display_title(full_title)
		title_edit.tooltip_text = full_title
		title_edit.custom_minimum_size = Vector2(TASK_ITEM_WIDTH - 22, 30)
		title_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_edit.expand_to_text_length = false
		title_edit.focus_entered.connect(_prepare_task_edit.bind(title_edit, task.task_id))
		title_edit.text_submitted.connect(_rename_task_submitted.bind(title_edit, task.task_id))
		title_edit.focus_exited.connect(_rename_task_from_edit.bind(title_edit, task.task_id))
		title_margin.add_child(title_edit)

		var archive := Button.new()
		archive.text = "x"
		archive.custom_minimum_size = Vector2(32, 30)
		archive.pressed.connect(_archive_task.bind(task.task_id))
		row.add_child(archive)


func _on_task_checkbox_toggled(pressed: bool, task_id: String) -> void:
	if pressed:
		_complete_task(task_id)


func _rename_task_from_edit(edit: LineEdit, task_id: String) -> void:
	var saved_title := _rename_task(edit.text, task_id)
	edit.text = _task_display_title(saved_title)
	edit.tooltip_text = saved_title


func _rename_task_submitted(new_title: String, edit: LineEdit, task_id: String) -> void:
	var saved_title := _rename_task(new_title, task_id)
	edit.text = _task_display_title(saved_title)
	edit.tooltip_text = saved_title


func _prepare_task_edit(edit: LineEdit, task_id: String) -> void:
	var full_title := _task_title(task_id)
	edit.text = full_title
	edit.tooltip_text = full_title
	edit.caret_column = edit.text.length()


func _rename_task(new_title: String, task_id: String) -> String:
	new_title = new_title.strip_edges()
	if new_title == "":
		new_title = "Type Here"
	for task in tasks:
		if task.task_id == task_id:
			task.title = new_title
			task.updated_at = Time.get_datetime_string_from_system(false, true)
			_save_game()
			return new_title
	return new_title


func _task_display_title(title: String) -> String:
	const MAX_TASK_DISPLAY_CHARS := 24
	if title.length() <= MAX_TASK_DISPLAY_CHARS:
		return title
	return "%s..." % title.substr(0, MAX_TASK_DISPLAY_CHARS - 3)


func _refresh_progress_ui() -> void:
	fp_label.text = "FP"
	fp_label.tooltip_text = "Focus Points: %d" % currencies.focus_points
	level_label.text = "LV"
	level_label.tooltip_text = "Level %d  XP %d / %d" % [level_progress.focus_level, level_progress.focus_xp, _xp_required_for_next_level()]
	bond_label.text = "BD"
	bond_label.tooltip_text = "Bond Lv.%d  %d / %d" % [bond_progress.bond_level, bond_progress.bond_points_current, _bond_required_for_next_level()]
	stats_label.text = "Completed: %d\nPartial: %d\nFocus minutes: %d\nTasks done: %d" % [
		daily_stats.completed_sessions,
		daily_stats.partial_sessions,
		daily_stats.focus_minutes_completed + daily_stats.focus_minutes_partial,
		daily_stats.tasks_completed
	]


func _update_stats(status: String, actual_sec: int) -> void:
	if session_mode != "focus":
		return
	var minutes := int(round(actual_sec / 60.0))
	if status == "completed":
		daily_stats.completed_sessions += 1
		daily_stats.focus_minutes_completed += minutes
	elif status == "partial":
		daily_stats.partial_sessions += 1
		daily_stats.focus_minutes_partial += minutes


func _format_time(seconds: int) -> String:
	var minutes := seconds / 60
	var secs := seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _status_title(status: String) -> String:
	match status:
		"completed":
			return "Completed"
		"partial":
			return "Partial"
		"abandoned":
			return "Abandoned"
	return status.capitalize()


func _task_title(task_id: String) -> String:
	for task in tasks:
		if task.task_id == task_id:
			return task.title
	return ""


func _task_status(task_id: String) -> String:
	for task in tasks:
		if task.task_id == task_id:
			return task.status
	return ""


func _load_spine_background(variant: String) -> void:
	if current_spine_variant == variant and spine_sprite != null:
		return
	current_spine_variant = variant

	if spine_sprite != null:
		spine_sprite.queue_free()
		spine_sprite = null

	if not ClassDB.class_exists("SpineSprite"):
		return

	var skeleton_path := "%s/%s/%s.skel" % [ASSET_ROOT, variant, variant]
	var atlas_path := "%s/%s/%s.atlas" % [ASSET_ROOT, variant, variant]
	var skeleton_res := ResourceLoader.load(skeleton_path)
	var atlas_res := ResourceLoader.load(atlas_path)
	if skeleton_res == null or atlas_res == null:
		push_warning("Unable to load Spine background: %s" % variant)
		return

	var data_res := SpineSkeletonDataResource.new()
	data_res.skeleton_file_res = skeleton_res
	data_res.atlas_res = atlas_res

	spine_sprite = SpineSprite.new()
	spine_sprite.name = "SpineBackground"
	spine_sprite.skeleton_data_res = data_res
	root_2d.add_child(spine_sprite)
	_play_spine_loop(spine_sprite)
	_fit_spine_to_viewport()


func _play_spine_loop(sprite: Node) -> void:
	var skeleton = sprite.get_skeleton()
	var skeleton_data = skeleton.get_data()
	var animations: Array = skeleton_data.get_animations()
	if animations.is_empty():
		return
	var animation_name: String = animations[0].get_name()
	for animation in animations:
		if animation.get_name() == "Loop":
			animation_name = "Loop"
			break
	sprite.get_animation_state().set_animation(animation_name, true, 0)


func _fit_spine_to_viewport() -> void:
	if spine_sprite == null:
		return
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = TARGET_VIEWPORT_SIZE

	if not spine_sprite.has_method("_edit_get_rect"):
		spine_sprite.scale = Vector2.ONE * 0.43
		spine_sprite.position = viewport_size * 0.5
		return

	var skeleton = spine_sprite.get_skeleton()
	skeleton.update_world_transform()
	var bounds: Rect2 = spine_sprite.call("_edit_get_rect")
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return

	var scale_factor: float = max(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y) * 1.02
	spine_sprite.scale = Vector2.ONE * scale_factor
	spine_sprite.position = viewport_size * 0.5 - (bounds.position + bounds.size * 0.5) * scale_factor


func _select_spine_variant() -> String:
	var mood := str(selected_context.mood)
	var time := str(selected_context.time)
	if mood == "normal":
		if time == "night":
			return "LofiBG_01_Nomal_Night"
		if time == "sunfall":
			return "LofiBG_01_Nomal_Sunfall"
		if selected_context.weather == "rain":
			return "LofiBG_01_Nomal_Cloudy"
		return "LofiBG_01_Nomal_Day"
	if mood == "good":
		if time == "night":
			return "LofiBG_01_Good_Night"
		if time == "sunfall":
			return "LofiBG_01_Good_Sunfall"
		return "LofiBG_01_Good_Day"
	if mood == "troubled":
		if time == "night":
			return "LofiBG_01_Troubled_Night"
		if time == "sunfall":
			return "LofiBG_01_Troubled_Sunfall"
		return "LofiBG_01_Troubled_Day"
	return "LofiBG_01_Nomal_Day"


func _apply_time_context() -> void:
	var hour: int = Time.get_datetime_dict_from_system().hour
	if hour >= 18 or hour < 6:
		selected_context.time = "night"
	elif hour >= 16:
		selected_context.time = "sunfall"
	else:
		selected_context.time = "day"


func _context_id() -> String:
	return "%s_%s_%s" % [selected_context.mood, selected_context.time, selected_context.weather]


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	tasks = parsed.get("tasks", tasks)
	sessions = parsed.get("sessions", sessions)
	currencies = parsed.get("currencies", currencies)
	level_progress = parsed.get("level_progress", level_progress)
	bond_progress = parsed.get("bond_progress", bond_progress)
	daily_stats = parsed.get("daily_stats", daily_stats)


func _save_game() -> void:
	var payload := {
		"tasks": tasks,
		"sessions": sessions,
		"currencies": currencies,
		"level_progress": level_progress,
		"bond_progress": bond_progress,
		"daily_stats": daily_stats
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "\t"))
