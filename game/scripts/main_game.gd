extends Node

const SaveDataService = preload("res://scripts/save_data_service.gd")
const TaskService = preload("res://scripts/task_service.gd")
const ProgressionService = preload("res://scripts/progression_service.gd")
const SpineBackgroundController = preload("res://scripts/spine_background_controller.gd")
const MusicPlayerController = preload("res://scripts/music_player_controller.gd")
const CompanionPanelController = preload("res://scripts/companion_panel_controller.gd")
const TimerRailController = preload("res://scripts/timer_rail_controller.gd")
const TimerSettingsController = preload("res://scripts/timer_settings_controller.gd")
const TimerSessionService = preload("res://scripts/timer_session_service.gd")
const LocalizationService = preload("res://scripts/localization_service.gd")
const OptionPanelController = preload("res://scripts/option_panel_controller.gd")

const SAVE_PATH := "user://save.json"
const ALARM_SOUND_PATH := "res://assets/sfx/alarm_placeholder.wav"
const TASK_PANEL_WIDTH := 430
const TASK_ITEM_WIDTH := 258
const SETTINGS_PANEL_WIDTH := 264
const TIMER_RAIL_WIDTH := 190
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

var spine_background: Node
var timer_rail: Node
var localizer
var option_controller: Node

var root_2d: Node2D
var ui_layer: CanvasLayer
var app_container: Control
var message_label: Label
var fp_label: Button
var level_label: Button
var bond_label: Button
var stats_label: Label
var duration_minutes := 25
var break_duration_minutes := 5
var auto_restart_enabled := false
var alarm_enabled := false
var timer_settings: Node
var task_list: VBoxContainer
var saved_music_path := ""
var music_loop := false
var music_volume := 0.7
var music_controller: Node
var companion_controller: Node
var alarm_player: AudioStreamPlayer
var result_dismiss_layer: Button
var result_panel: PanelContainer
var result_title: Label
var result_rewards: Label
var mark_task_done_button: Button
var break_button: Button
var language_code := "en"
var tasks_title_label: Label
var add_task_button: Button
var unlocks_label: Button
var stats_button: Button


func _ready() -> void:
	_load_save()
	localizer = LocalizationService.new(language_code)
	_apply_time_context()
	_build_scene()
	spine_background.load_selected_background()
	_refresh_all()


func _process(delta: float) -> void:
	if app_state != "running":
		return

	var tick := TimerSessionService.advance(elapsed_sec, delta, planned_duration_sec)
	elapsed_sec = float(tick.elapsed_sec)
	if tick.finished:
		if session_mode == "focus":
			_finish_session("completed", true)
		else:
			_finish_break()
		return

	_refresh_timer_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()


func _build_scene() -> void:
	root_2d = Node2D.new()
	root_2d.name = "World"
	add_child(root_2d)

	spine_background = SpineBackgroundController.new()
	add_child(spine_background)
	spine_background.setup(root_2d, selected_context)

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

	message_label = Label.new()
	message_label.visible = false
	layers.add_child(message_label)

	option_controller = OptionPanelController.new()
	add_child(option_controller)
	option_controller.setup(layers, localizer)
	option_controller.language_previous_pressed.connect(_on_previous_language_pressed)
	option_controller.language_next_pressed.connect(_on_next_language_pressed)

	_build_top_bar(layers)
	_build_task_panel(layers)
	timer_rail = TimerRailController.new()
	add_child(timer_rail)
	timer_rail.setup(layers, localizer)
	timer_rail.primary_pressed.connect(_on_primary_timer_pressed)
	timer_rail.reset_pressed.connect(_on_reset_pressed)
	timer_rail.settings_pressed.connect(_toggle_settings_panel)
	timer_settings = TimerSettingsController.new()
	add_child(timer_settings)
	timer_settings.setup(
		layers,
		TIMER_RAIL_WIDTH,
		SETTINGS_PANEL_WIDTH,
		duration_minutes,
		break_duration_minutes,
		auto_restart_enabled,
		alarm_enabled,
		localizer
	)
	timer_settings.focus_duration_delta_requested.connect(_adjust_duration_minutes)
	timer_settings.break_duration_delta_requested.connect(_adjust_break_duration_minutes)
	timer_settings.auto_restart_pressed.connect(_on_auto_restart_toggled)
	timer_settings.alarm_pressed.connect(_on_alarm_toggled)
	_build_result_dismiss_layer(layers)
	_build_result_panel(layers)
	companion_controller = CompanionPanelController.new()
	add_child(companion_controller)
	companion_controller.setup(layers, localizer)
	_build_stats_overlay(layers)
	music_controller = MusicPlayerController.new()
	add_child(music_controller)
	music_controller.state_changed.connect(_save_game)
	music_controller.setup(layers, saved_music_path, music_loop, music_volume, localizer)
	_build_alarm_player()


func _build_top_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.name = "TopBar"
	bar.anchor_left = 1.0
	bar.anchor_top = 0.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_left = -380
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
	unlocks_label = unlocks
	row.add_child(unlocks)

	var stats := _new_icon_button("ST", "Stats")
	stats_button = stats
	stats.pressed.connect(_toggle_stats_message)
	row.add_child(stats)

	var option_button := option_controller.create_top_bar_button() as Button
	row.add_child(option_button)
	option_controller.refresh_text()


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
	result_title = _new_title(localizer.translate("result.title"))
	box.add_child(result_title)
	result_rewards = _new_muted_label("")
	box.add_child(result_rewards)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	mark_task_done_button = Button.new()
	mark_task_done_button.text = localizer.translate("result.mark_task_done")
	mark_task_done_button.custom_minimum_size = Vector2(126, 30)
	mark_task_done_button.pressed.connect(_on_mark_bound_task_done)
	buttons.add_child(mark_task_done_button)

	break_button = Button.new()
	break_button.text = localizer.translate("result.start_break")
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


func _build_stats_overlay(parent: Control) -> void:
	stats_label = _new_muted_label("")
	stats_label.visible = false
	stats_label.anchor_left = 1.0
	stats_label.anchor_top = 1.0
	stats_label.anchor_right = 1.0
	stats_label.anchor_bottom = 1.0
	stats_label.offset_left = -250
	stats_label.offset_top = -156
	stats_label.offset_right = 0
	stats_label.offset_bottom = -58
	parent.add_child(stats_label)


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

	var title := _new_title(localizer.translate("tasks.title"))
	tasks_title_label = title
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)

	var add_button := Button.new()
	add_button.text = "+"
	add_button.tooltip_text = localizer.translate("tasks.add")
	add_button.custom_minimum_size = Vector2(34, 32)
	add_button.pressed.connect(_on_add_task_pressed)
	header.add_child(add_button)
	add_task_button = add_button

	task_list = VBoxContainer.new()
	task_list.add_theme_constant_override("separation", 6)
	box.add_child(task_list)


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


func _build_alarm_player() -> void:
	if DisplayServer.get_name() == "headless":
		return
	alarm_player = AudioStreamPlayer.new()
	alarm_player.name = "AlarmPlayer"
	if ResourceLoader.exists(ALARM_SOUND_PATH):
		alarm_player.stream = load(ALARM_SOUND_PATH)
	if alarm_player.stream == null:
		alarm_player.stream = _new_silent_alarm_stream()
	add_child(alarm_player)


func _new_silent_alarm_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.data = PackedByteArray()
	return stream


func _on_primary_timer_pressed() -> void:
	match TimerSessionService.primary_action(app_state):
		"resume":
			_apply_timer_state(TimerSessionService.resume())
			_refresh_all()
		"pause":
			_apply_timer_state(TimerSessionService.pause())
			_refresh_all()
		_:
			_start_focus_session()


func _start_focus_session() -> void:
	if app_state == "running":
		return
	_hide_break_interaction()
	if timer_settings != null and timer_settings.has_method("hide"):
		timer_settings.hide()
	var next_state := TimerSessionService.start_focus(duration_minutes, _selected_task_id())
	_apply_timer_state(next_state)
	if active_task_id != "":
		_set_task_status(active_task_id, "in_progress")
	spine_background.load_selected_background()
	_refresh_all()


func _on_end_pressed() -> void:
	if app_state == "running" or app_state == "paused":
		_finish_session(TimerSessionService.classify_early_end(elapsed_sec, planned_duration_sec))


func _on_reset_pressed() -> void:
	_apply_timer_state(TimerSessionService.reset_focus(duration_minutes))
	result_dismissed = true
	_dismiss_result_panel()
	_hide_break_interaction()
	_refresh_all()


func _on_break_pressed() -> void:
	_start_break_countdown()
	_dismiss_result_panel()


func _start_break_countdown() -> void:
	_apply_timer_state(TimerSessionService.start_break(break_duration_minutes))
	_show_break_interaction()
	_refresh_all()


func _finish_break() -> void:
	_play_alarm()
	_hide_break_interaction()
	if auto_restart_enabled:
		app_state = "idle"
		_start_focus_session()
		return
	_apply_timer_state(TimerSessionService.finish_break(duration_minutes))
	_refresh_all()


func _show_break_interaction() -> void:
	if companion_controller != null and companion_controller.has_method("show_break_interaction"):
		companion_controller.show_break_interaction()


func _hide_break_interaction() -> void:
	if companion_controller != null and companion_controller.has_method("hide_break_interaction"):
		companion_controller.hide_break_interaction()


func _apply_timer_state(next_state: Dictionary) -> void:
	if next_state.has("app_state"):
		app_state = str(next_state.app_state)
	if next_state.has("session_mode"):
		session_mode = str(next_state.session_mode)
	if next_state.has("planned_duration_sec"):
		planned_duration_sec = int(next_state.planned_duration_sec)
	if next_state.has("elapsed_sec"):
		elapsed_sec = float(next_state.elapsed_sec)
	if next_state.has("session_started_at"):
		session_started_at = str(next_state.session_started_at)
	if next_state.has("active_task_id"):
		active_task_id = str(next_state.active_task_id)
	if next_state.has("message_key") and str(next_state.message_key) != "":
		message_label.text = localizer.translate(str(next_state.message_key))
		return
	if next_state.has("message"):
		message_label.text = str(next_state.message)


func _finish_session(status: String, start_break_after: bool = false) -> void:
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
	selected_context.mood = "good" if status == "completed" else "troubled"
	spine_background.load_selected_background()
	_save_game()
	_play_alarm()
	if start_break_after:
		_start_break_countdown()
		return
	app_state = status
	result_dismissed = false
	result_title.text = _status_title(status)
	result_rewards.text = _reward_summary(rewards)
	message_label.text = localizer.translate("timer.message_session_logged")
	_refresh_all()


func _grant_rewards(status: String, actual_sec: int) -> Dictionary:
	return ProgressionService.grant_session_rewards(
		session_mode,
		status,
		actual_sec,
		planned_duration_sec,
		currencies,
		level_progress,
		bond_progress,
		MIN_REWARDABLE_SESSION_SEC,
		BASE_FOCUS_POINTS,
		BASE_BOND,
		BASE_XP
	)


func _add_xp(amount: int) -> void:
	ProgressionService.add_xp(level_progress, amount)


func _add_bond(amount: int) -> void:
	ProgressionService.add_bond(bond_progress, amount)


func _xp_required_for_next_level() -> int:
	return ProgressionService.xp_required_for_next_level(level_progress)


func _bond_required_for_next_level() -> int:
	return ProgressionService.bond_required_for_next_level(bond_progress)


func _on_add_task_pressed() -> void:
	_create_task(localizer.translate("tasks.default_title"))


func _on_task_submitted(text: String) -> void:
	_create_task(text)


func _create_task(title: String) -> void:
	var task := TaskService.create_task(tasks, title)
	if task.is_empty():
		return
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
		result_rewards.text += "\n%s" % localizer.trf("result.task_bonus", {
			"focus_points": TASK_BONUS_FOCUS_POINTS,
			"xp": TASK_BONUS_XP
		})
		_save_game()
		_refresh_all()


func _set_task_status(task_id: String, status: String) -> bool:
	return TaskService.set_task_status(tasks, task_id, status)


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
	return TaskService.selected_task_id(tasks)


func _refresh_all() -> void:
	_refresh_timer_ui()
	_refresh_tasks_ui()
	_refresh_progress_ui()
	_refresh_controls()


func _refresh_timer_ui() -> void:
	if timer_rail != null and timer_rail.has_method("refresh_timer"):
		timer_rail.refresh_timer(
			app_state,
			session_mode,
			planned_duration_sec,
			elapsed_sec,
			duration_minutes,
			break_duration_minutes
		)
	if timer_settings != null and timer_settings.has_method("refresh_durations"):
		timer_settings.refresh_durations(duration_minutes, break_duration_minutes)


func _refresh_controls() -> void:
	if timer_rail != null and timer_rail.has_method("refresh_controls"):
		timer_rail.refresh_controls(app_state)
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
	var settings := TimerSessionService.set_focus_duration(minutes)
	duration_minutes = int(settings.duration_minutes)
	planned_duration_sec = int(settings.planned_duration_sec)
	_save_game()
	_refresh_timer_ui()


func _adjust_duration_minutes(delta_minutes: int) -> void:
	_set_duration_minutes(duration_minutes + delta_minutes)


func _adjust_break_duration_minutes(delta_minutes: int) -> void:
	if app_state == "running" or app_state == "paused":
		return
	break_duration_minutes = TimerSessionService.set_break_duration(break_duration_minutes + delta_minutes)
	_save_game()
	_refresh_timer_ui()


func _toggle_settings_panel() -> void:
	if timer_settings != null and timer_settings.has_method("toggle_visible"):
		timer_settings.toggle_visible()


func _on_auto_restart_toggled() -> void:
	auto_restart_enabled = not auto_restart_enabled
	if timer_settings != null and timer_settings.has_method("refresh_auto_restart"):
		timer_settings.refresh_auto_restart(auto_restart_enabled)
	_save_game()


func _on_alarm_toggled() -> void:
	alarm_enabled = not alarm_enabled
	if timer_settings != null and timer_settings.has_method("refresh_alarm"):
		timer_settings.refresh_alarm(alarm_enabled)
	_save_game()


func _on_previous_language_pressed() -> void:
	language_code = localizer.previous_language()
	_refresh_localized_text()
	_save_game()


func _on_next_language_pressed() -> void:
	language_code = localizer.next_language()
	_refresh_localized_text()
	_save_game()


func _refresh_localized_text() -> void:
	if tasks_title_label != null:
		tasks_title_label.text = localizer.translate("tasks.title")
	if add_task_button != null:
		add_task_button.tooltip_text = localizer.translate("tasks.add")
	if mark_task_done_button != null:
		mark_task_done_button.text = localizer.translate("result.mark_task_done")
	if break_button != null:
		break_button.text = localizer.translate("result.start_break")
	if result_title != null:
		if app_state == "completed" or app_state == "partial" or app_state == "abandoned":
			result_title.text = _status_title(app_state)
		else:
			result_title.text = localizer.translate("result.title")
	if timer_rail != null and timer_rail.has_method("set_localizer"):
		timer_rail.set_localizer(localizer)
	if timer_settings != null and timer_settings.has_method("set_localizer"):
		timer_settings.set_localizer(localizer)
	if companion_controller != null and companion_controller.has_method("set_localizer"):
		companion_controller.set_localizer(localizer)
	if music_controller != null and music_controller.has_method("set_localizer"):
		music_controller.set_localizer(localizer)
	if option_controller != null and option_controller.has_method("refresh_text"):
		option_controller.refresh_text()
	_refresh_all()


func _play_alarm() -> void:
	if not alarm_enabled or alarm_player == null or alarm_player.stream == null:
		return
	alarm_player.stop()
	alarm_player.play()


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
		title_edit.text = full_title
		title_edit.tooltip_text = full_title
		title_edit.custom_minimum_size = Vector2(TASK_ITEM_WIDTH - 22, 30)
		title_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_edit.expand_to_text_length = false
		title_edit.add_theme_stylebox_override("normal", _new_task_edit_style(false))
		title_edit.add_theme_stylebox_override("focus", _new_task_edit_style(true))
		title_edit.focus_entered.connect(_prepare_task_edit.bind(title_edit, task.task_id))
		title_edit.text_submitted.connect(_rename_task_submitted.bind(title_edit, task.task_id))
		title_edit.focus_exited.connect(_rename_task_from_edit.bind(title_edit, task.task_id))
		title_margin.add_child(title_edit)

		var archive := Button.new()
		archive.text = "x"
		archive.tooltip_text = localizer.translate("tasks.archive")
		archive.custom_minimum_size = Vector2(32, 30)
		archive.pressed.connect(_archive_task.bind(task.task_id))
		row.add_child(archive)


func _on_task_checkbox_toggled(pressed: bool, task_id: String) -> void:
	if pressed:
		_complete_task(task_id)


func _rename_task_from_edit(edit: LineEdit, task_id: String) -> void:
	var saved_title := _rename_task(edit.text, task_id)
	edit.text = saved_title
	edit.tooltip_text = saved_title


func _rename_task_submitted(new_title: String, edit: LineEdit, task_id: String) -> void:
	var saved_title := _rename_task(new_title, task_id)
	edit.text = saved_title
	edit.tooltip_text = saved_title


func _prepare_task_edit(edit: LineEdit, task_id: String) -> void:
	var full_title := _task_title(task_id)
	edit.text = full_title
	edit.tooltip_text = full_title
	edit.caret_column = edit.text.length()


func _rename_task(new_title: String, task_id: String) -> String:
	var saved_title: String = TaskService.rename_task(tasks, new_title, task_id, localizer.translate("tasks.default_title"))
	_save_game()
	return saved_title


func _task_display_title(title: String) -> String:
	const MAX_TASK_DISPLAY_CHARS := 24
	if title.length() <= MAX_TASK_DISPLAY_CHARS:
		return title
	return "%s..." % title.substr(0, MAX_TASK_DISPLAY_CHARS - 3)


func _new_task_edit_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.068, 0.72)
	style.border_color = Color(1, 1, 1, 0.78) if focused else Color(1, 1, 1, 0.0)
	style.set_border_width_all(2 if focused else 0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _refresh_progress_ui() -> void:
	fp_label.text = "FP"
	fp_label.tooltip_text = "%s: %d" % [localizer.translate("top.focus_points"), currencies.focus_points]
	level_label.text = "LV"
	level_label.tooltip_text = "%s %d  XP %d / %d" % [localizer.translate("top.focus_level"), level_progress.focus_level, level_progress.focus_xp, _xp_required_for_next_level()]
	bond_label.text = "BD"
	bond_label.tooltip_text = "%s Lv.%d  %d / %d" % [localizer.translate("top.bond"), bond_progress.bond_level, bond_progress.bond_points_current, _bond_required_for_next_level()]
	if unlocks_label != null:
		unlocks_label.tooltip_text = localizer.translate("top.unlocks")
	if stats_button != null:
		stats_button.tooltip_text = localizer.translate("top.stats")
	stats_label.text = "%s: %d\n%s: %d\n%s: %d\n%s: %d" % [
		localizer.translate("stats.completed"),
		daily_stats.completed_sessions,
		localizer.translate("stats.partial"),
		daily_stats.partial_sessions,
		localizer.translate("stats.focus_minutes"),
		daily_stats.focus_minutes_completed + daily_stats.focus_minutes_partial,
		localizer.translate("stats.tasks_done"),
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
	return localizer.translate("timer.state_%s" % status)


func _reward_summary(rewards: Dictionary) -> String:
	if not bool(rewards.get("rewardable", false)):
		return localizer.translate("result.no_reward")
	return localizer.trf("result.reward_summary", {
		"focus_points": int(rewards.get("focus_points", 0)),
		"xp": int(rewards.get("xp", 0)),
		"bond": int(rewards.get("bond", 0))
	})


func _task_title(task_id: String) -> String:
	return TaskService.task_title(tasks, task_id)


func _task_status(task_id: String) -> String:
	return TaskService.task_status(tasks, task_id)


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
	var parsed := SaveDataService.load_payload(SAVE_PATH, {})
	if parsed.is_empty():
		return
	tasks = parsed.get("tasks", tasks)
	sessions = parsed.get("sessions", sessions)
	currencies = parsed.get("currencies", currencies)
	level_progress = parsed.get("level_progress", level_progress)
	bond_progress = parsed.get("bond_progress", bond_progress)
	daily_stats = parsed.get("daily_stats", daily_stats)
	var timer_settings = parsed.get("timer_settings", {})
	if typeof(timer_settings) == TYPE_DICTIONARY:
		duration_minutes = int(timer_settings.get("focus_minutes", duration_minutes))
		break_duration_minutes = int(timer_settings.get("break_minutes", break_duration_minutes))
		auto_restart_enabled = bool(timer_settings.get("auto_restart", auto_restart_enabled))
		alarm_enabled = bool(timer_settings.get("alarm", alarm_enabled))
	var music_state = parsed.get("music_state", {})
	if typeof(music_state) == TYPE_DICTIONARY:
		saved_music_path = str(music_state.get("current_path", saved_music_path))
		music_loop = bool(music_state.get("loop", music_loop))
		music_volume = float(music_state.get("volume", music_volume))
	var app_settings = parsed.get("app_settings", {})
	if typeof(app_settings) == TYPE_DICTIONARY:
		language_code = str(app_settings.get("language", language_code))


func _save_game() -> void:
	var current_music_state := {
		"current_path": saved_music_path,
		"loop": music_loop,
		"volume": music_volume
	}
	if music_controller != null and music_controller.has_method("get_state"):
		current_music_state = music_controller.get_state()
	var payload := {
		"tasks": tasks,
		"sessions": sessions,
		"currencies": currencies,
		"level_progress": level_progress,
		"bond_progress": bond_progress,
		"daily_stats": daily_stats,
		"timer_settings": {
			"focus_minutes": duration_minutes,
			"break_minutes": break_duration_minutes,
			"auto_restart": auto_restart_enabled,
			"alarm": alarm_enabled
		},
		"music_state": current_music_state,
		"app_settings": {
			"language": language_code
		}
	}
	SaveDataService.save_payload(SAVE_PATH, payload)
