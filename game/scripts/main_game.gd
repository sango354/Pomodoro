extends Node

const SaveDataService = preload("res://scripts/save_data_service.gd")
const ProgressionService = preload("res://scripts/progression_service.gd")
const SpineBackgroundController = preload("res://scripts/spine_background_controller.gd")
const MusicPlayerController = preload("res://scripts/music_player_controller.gd")
const CompanionPanelController = preload("res://scripts/companion_panel_controller.gd")
const TimerRailController = preload("res://scripts/timer_rail_controller.gd")
const TimerSettingsController = preload("res://scripts/timer_settings_controller.gd")
const TimerSessionService = preload("res://scripts/timer_session_service.gd")
const LocalizationService = preload("res://scripts/localization_service.gd")
const OptionPanelController = preload("res://scripts/option_panel_controller.gd")
const TaskPanelController = preload("res://scripts/task_panel_controller.gd")
const ResultPanelController = preload("res://scripts/result_panel_controller.gd")
const SessionRewardCoordinator = preload("res://scripts/session_reward_coordinator.gd")
const BreakMediaController = preload("res://scripts/break_media_controller.gd")
const ContentUnlockService = preload("res://scripts/content_unlock_service.gd")
const StorePanelController = preload("res://scripts/store_panel_controller.gd")

const SAVE_PATH := "user://save.json"
const ALARM_SOUND_PATH := "res://assets/sfx/alarm_placeholder.wav"
const DEFAULT_BREAK_MEDIA_PATH := "res://assets/videos/break/video.mp4"
const SETTINGS_PANEL_WIDTH := 264
const TIMER_RAIL_WIDTH := 190
const DEFAULT_FOCUS_MINUTES := 5
const DEFAULT_BREAK_MINUTES := 5
const MIN_REWARDABLE_SESSION_SEC := 300
const BASE_FOCUS_POINTS := 20
const BASE_BOND := 10
const BASE_XP := 30
const TASK_BONUS_FOCUS_POINTS := 8
const TASK_BONUS_XP := 10
const AMBIENT_PROMPT_LOW := "low"
const AMBIENT_PROMPT_NORMAL := "normal"
const AMBIENT_PROMPT_OFF := "off"
const AMBIENT_PROMPT_INITIAL_IDLE_SEC := 20
const AMBIENT_PROMPT_LOW_IDLE_INTERVAL_SEC := 90
const AMBIENT_PROMPT_NORMAL_IDLE_INTERVAL_SEC := 3 * 60
const AMBIENT_PROMPT_FOCUS_INTERVAL_SEC := 8 * 60
const AMBIENT_PROMPT_VISIBLE_SEC := 8.0

var app_state := "idle"
var session_mode := "focus"
var result_dismissed := false
var planned_duration_sec := DEFAULT_FOCUS_MINUTES * 60
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
var task_controller: Node
var result_controller: Node
var break_media_controller: Node
var store_controller: Node

var root_2d: Node2D
var ui_layer: CanvasLayer
var app_container: Control
var message_label: Label
var fp_label: Button
var level_label: Button
var bond_label: Button
var stats_label: Label
var duration_minutes := DEFAULT_FOCUS_MINUTES
var break_duration_minutes := DEFAULT_BREAK_MINUTES
var auto_restart_enabled := false
var alarm_enabled := false
var timer_settings: Node
var saved_music_path := ""
var music_loop := false
var music_volume := 0.7
var music_controller: Node
var companion_controller: Node
var alarm_player: AudioStreamPlayer
var language_code := "en"
var break_media_enabled := false
var break_media_path := DEFAULT_BREAK_MEDIA_PATH
var ambient_prompt_frequency := AMBIENT_PROMPT_NORMAL
var interaction_history: Array = []
var background_defs: Array = []
var unlocked_content: Array = []
var ambient_prompt_elapsed_sec := 0.0
var ambient_prompt_visible_sec := 0.0
var ambient_prompt_has_shown := false
var unlocks_label: Button
var store_button: Button
var stats_button: Button


func _ready() -> void:
	_load_save()
	background_defs = ContentUnlockService.load_background_defs()
	localizer = LocalizationService.new(language_code)
	_apply_time_context()
	_build_scene()
	spine_background.load_selected_background()
	_refresh_all()


func _process(delta: float) -> void:
	_update_ambient_prompt(delta)
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
	spine_background.setup(root_2d, selected_context, background_defs, unlocked_content)

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
	option_controller.setup(layers, localizer, break_media_enabled, ambient_prompt_frequency)
	option_controller.language_previous_pressed.connect(_on_previous_language_pressed)
	option_controller.language_next_pressed.connect(_on_next_language_pressed)
	option_controller.break_media_pressed.connect(_on_break_media_toggled)
	option_controller.ambient_prompt_pressed.connect(_on_ambient_prompt_frequency_pressed)

	_build_top_bar(layers)
	store_controller = StorePanelController.new()
	add_child(store_controller)
	store_controller.setup(layers, localizer)
	store_controller.purchase_requested.connect(_on_store_purchase_requested)
	task_controller = TaskPanelController.new()
	add_child(task_controller)
	task_controller.setup(layers, tasks, localizer)
	task_controller.tasks_changed.connect(_on_tasks_changed)
	task_controller.task_renamed.connect(_on_task_renamed)
	task_controller.task_completed.connect(_on_task_completed)
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
	result_controller = ResultPanelController.new()
	add_child(result_controller)
	result_controller.setup(layers, localizer)
	result_controller.mark_task_done_pressed.connect(_on_mark_bound_task_done)
	result_controller.break_pressed.connect(_on_break_pressed)
	companion_controller = CompanionPanelController.new()
	add_child(companion_controller)
	companion_controller.setup(layers, localizer)
	companion_controller.break_interaction_viewed.connect(_on_break_interaction_viewed)
	companion_controller.break_interaction_skipped.connect(_on_break_interaction_skipped)
	companion_controller.break_interaction_advanced.connect(_on_break_interaction_advanced)
	companion_controller.ambient_prompt_shown.connect(_on_ambient_prompt_shown)
	companion_controller.ambient_prompt_dismissed.connect(_on_ambient_prompt_dismissed)
	break_media_controller = BreakMediaController.new()
	add_child(break_media_controller)
	break_media_controller.setup(layers, break_media_enabled, break_media_path)
	break_media_controller.playback_failed.connect(_on_break_media_failed)
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

	var shop := _new_icon_button("SH", "Store")
	store_button = shop
	shop.pressed.connect(_toggle_store_panel)
	row.add_child(shop)

	var stats := _new_icon_button("ST", "Stats")
	stats_button = stats
	stats.pressed.connect(_toggle_stats_message)
	row.add_child(stats)

	var option_button := option_controller.create_top_bar_button() as Button
	row.add_child(option_button)
	option_controller.refresh_text()


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
	_dismiss_result_panel()
	_hide_break_interaction()
	_hide_ambient_prompt()
	_stop_break_media()
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
	_hide_ambient_prompt()
	_stop_break_media()
	_refresh_all()


func _on_break_pressed() -> void:
	_start_break_countdown()
	_dismiss_result_panel()


func _start_break_countdown() -> void:
	_hide_ambient_prompt()
	_apply_timer_state(TimerSessionService.start_break(break_duration_minutes))
	if not _start_break_media():
		_show_break_interaction()
	_refresh_all()


func _finish_break() -> void:
	_play_alarm()
	_hide_break_interaction()
	_hide_ambient_prompt()
	_stop_break_media()
	if auto_restart_enabled:
		app_state = "idle"
		_start_focus_session()
		return
	_apply_timer_state(TimerSessionService.finish_break(duration_minutes))
	_refresh_all()


func _show_break_interaction() -> void:
	if companion_controller != null and companion_controller.has_method("show_break_interaction"):
		companion_controller.show_break_interaction(
			int(bond_progress.get("bond_level", 1)),
			selected_context,
			interaction_history
		)


func _hide_break_interaction() -> void:
	if companion_controller != null and companion_controller.has_method("hide_break_interaction"):
		companion_controller.hide_break_interaction()


func _show_ambient_prompt() -> void:
	if companion_controller == null or not companion_controller.has_method("show_ambient_prompt"):
		return
	companion_controller.show_ambient_prompt(
		int(bond_progress.get("bond_level", 1)),
		selected_context,
		interaction_history
	)
	ambient_prompt_visible_sec = 0.0


func _hide_ambient_prompt(emit_dismissed: bool = false) -> void:
	if companion_controller != null and companion_controller.has_method("hide_ambient_prompt"):
		companion_controller.hide_ambient_prompt(emit_dismissed)
	ambient_prompt_visible_sec = 0.0


func _update_ambient_prompt(delta: float) -> void:
	if _is_ambient_prompt_visible():
		ambient_prompt_visible_sec += delta
		if ambient_prompt_visible_sec >= AMBIENT_PROMPT_VISIBLE_SEC:
			_hide_ambient_prompt()
		return
	if not _ambient_prompt_allowed():
		ambient_prompt_elapsed_sec = 0.0
		return
	ambient_prompt_elapsed_sec += delta
	var interval := _ambient_prompt_interval_sec()
	if app_state == "idle" and not ambient_prompt_has_shown:
		interval = AMBIENT_PROMPT_INITIAL_IDLE_SEC
	if ambient_prompt_elapsed_sec >= interval:
		ambient_prompt_elapsed_sec = 0.0
		ambient_prompt_has_shown = true
		_show_ambient_prompt()


func _ambient_prompt_allowed() -> bool:
	if ambient_prompt_frequency == AMBIENT_PROMPT_OFF:
		return false
	if session_mode == "short_break":
		return false
	if app_state != "idle" and not (app_state == "running" and session_mode == "focus"):
		return false
	if result_controller != null and result_controller.has_method("is_result_visible") and result_controller.is_result_visible():
		return false
	return true


func _ambient_prompt_interval_sec() -> int:
	if app_state == "running":
		return AMBIENT_PROMPT_FOCUS_INTERVAL_SEC
	return AMBIENT_PROMPT_LOW_IDLE_INTERVAL_SEC if ambient_prompt_frequency == AMBIENT_PROMPT_LOW else AMBIENT_PROMPT_NORMAL_IDLE_INTERVAL_SEC


func _is_ambient_prompt_visible() -> bool:
	if companion_controller == null or not companion_controller.has_method("is_ambient_prompt_visible"):
		return false
	return companion_controller.is_ambient_prompt_visible()


func _start_break_media() -> bool:
	if break_media_controller == null or not break_media_controller.has_method("play_break_media"):
		return false
	return break_media_controller.play_break_media()


func _stop_break_media() -> void:
	if break_media_controller != null and break_media_controller.has_method("stop_break_media"):
		break_media_controller.stop_break_media()


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
	var previous_bond_level := int(bond_progress.get("bond_level", 1))
	var rewards := _grant_rewards(status, actual_sec)
	var current_bond_level := int(bond_progress.get("bond_level", 1))
	var bond_level_up_text := ""
	if current_bond_level > previous_bond_level:
		bond_level_up_text = _bond_level_up_summary(current_bond_level)
		_record_interaction_event("bond_level_up", "bond_level_%d" % current_bond_level)
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
	_show_result_panel(status, actual_sec, rewards, bond_level_up_text, not start_break_after)
	if start_break_after:
		_start_break_countdown()
		return
	app_state = status
	message_label.text = localizer.translate("timer.message_session_logged")
	_refresh_all()


func _grant_rewards(status: String, actual_sec: int) -> Dictionary:
	return SessionRewardCoordinator.grant_session_rewards(
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


func _show_result_panel(status: String, actual_sec: int, rewards: Dictionary, bond_level_up_text: String, can_start_break: bool) -> void:
	result_dismissed = false
	if result_controller == null or not result_controller.has_method("show_result"):
		return
	var reward_text := _result_summary(status, actual_sec, rewards, bond_level_up_text)
	result_controller.show_result(
		status,
		reward_text,
		active_task_id != "" and _task_status(active_task_id) != "done",
		can_start_break and status != "abandoned"
	)


func _add_xp(amount: int) -> void:
	ProgressionService.add_xp(level_progress, amount)


func _add_bond(amount: int) -> void:
	ProgressionService.add_bond(bond_progress, amount)


func _xp_required_for_next_level() -> int:
	return ProgressionService.xp_required_for_next_level(level_progress)


func _bond_required_for_next_level() -> int:
	return ProgressionService.bond_required_for_next_level(bond_progress)


func _on_mark_bound_task_done() -> void:
	var result := SessionRewardCoordinator.apply_task_completion_bonus(
		tasks,
		active_task_id,
		currencies,
		level_progress,
		daily_stats,
		TASK_BONUS_FOCUS_POINTS,
		TASK_BONUS_XP,
		localizer
	)
	if bool(result.get("changed", false)):
		if result_controller != null and result_controller.has_method("append_reward_line"):
			result_controller.append_reward_line(str(result.get("summary", "")))
		_save_game()
		_refresh_all()


func _set_task_status(task_id: String, status: String) -> bool:
	if task_controller != null and task_controller.has_method("set_task_status"):
		return task_controller.set_task_status(task_id, status)
	return false


func _on_tasks_changed() -> void:
	_save_game()
	_refresh_all()


func _on_task_renamed() -> void:
	_save_game()


func _on_task_completed(_task_id: String) -> void:
	daily_stats.tasks_completed += 1


func _selected_task_id() -> String:
	if task_controller != null and task_controller.has_method("selected_task_id"):
		return task_controller.selected_task_id()
	return ""


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
	if result_controller != null and result_controller.has_method("refresh_controls"):
		result_controller.refresh_controls(app_state, active_task_id, _task_status(active_task_id) == "done")


func _dismiss_result_panel() -> void:
	result_dismissed = true
	if result_controller != null and result_controller.has_method("hide_result"):
		result_controller.hide_result()


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


func _on_break_media_toggled() -> void:
	break_media_enabled = not break_media_enabled
	if option_controller != null and option_controller.has_method("refresh_break_media"):
		option_controller.refresh_break_media(break_media_enabled)
	var is_break_running := session_mode == "short_break" and app_state == "running"
	if not is_break_running and break_media_controller != null and break_media_controller.has_method("set_enabled"):
		break_media_controller.set_enabled(break_media_enabled)
	_save_game()


func _on_ambient_prompt_frequency_pressed() -> void:
	if ambient_prompt_frequency == AMBIENT_PROMPT_NORMAL:
		ambient_prompt_frequency = AMBIENT_PROMPT_LOW
	elif ambient_prompt_frequency == AMBIENT_PROMPT_LOW:
		ambient_prompt_frequency = AMBIENT_PROMPT_OFF
	else:
		ambient_prompt_frequency = AMBIENT_PROMPT_NORMAL
	ambient_prompt_elapsed_sec = 0.0
	if ambient_prompt_frequency == AMBIENT_PROMPT_OFF:
		_hide_ambient_prompt(true)
	if option_controller != null and option_controller.has_method("refresh_ambient_prompt"):
		option_controller.refresh_ambient_prompt(ambient_prompt_frequency)
	_save_game()


func _refresh_localized_text() -> void:
	if task_controller != null and task_controller.has_method("set_localizer"):
		task_controller.set_localizer(localizer)
	if result_controller != null and result_controller.has_method("set_localizer"):
		result_controller.set_localizer(localizer)
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
	if store_controller != null and store_controller.has_method("set_localizer"):
		store_controller.set_localizer(localizer)
	_refresh_all()


func _on_break_interaction_viewed(dialogue_id: String) -> void:
	_record_interaction_event("break_interaction_viewed", dialogue_id)


func _on_break_interaction_skipped(dialogue_id: String) -> void:
	_record_interaction_event("break_interaction_skipped", dialogue_id)


func _on_break_interaction_advanced(from_id: String, to_id: String) -> void:
	_record_interaction_event("break_interaction_advanced", "%s>%s" % [from_id, to_id])


func _on_ambient_prompt_shown(dialogue_id: String) -> void:
	_record_interaction_event("ambient_prompt_shown", dialogue_id)


func _on_ambient_prompt_dismissed(dialogue_id: String) -> void:
	_record_interaction_event("ambient_prompt_dismissed", dialogue_id)


func _on_break_media_failed(_path: String) -> void:
	if session_mode == "short_break" and app_state == "running":
		_show_break_interaction()


func _record_interaction_event(event_type: String, dialogue_id: String) -> void:
	interaction_history.append({
		"event_type": event_type,
		"dialogue_id": dialogue_id,
		"created_at": Time.get_datetime_string_from_system(false, true),
		"context_id": _context_id()
	})
	if interaction_history.size() > 200:
		interaction_history.pop_front()
	_save_game()


func _play_alarm() -> void:
	if not alarm_enabled or alarm_player == null or alarm_player.stream == null:
		return
	alarm_player.stop()
	alarm_player.play()


func _toggle_stats_message() -> void:
	stats_label.visible = not stats_label.visible


func _toggle_store_panel() -> void:
	if store_controller == null:
		return
	if store_controller.has_method("is_store_visible") and store_controller.is_store_visible():
		store_controller.hide_store()
		return
	store_controller.show_store(_store_items())


func _store_items() -> Array:
	return ContentUnlockService.store_items(background_defs, unlocked_content, localizer)


func _on_store_purchase_requested(content_id: String) -> void:
	var result := ContentUnlockService.purchase_background(content_id, background_defs, unlocked_content, currencies)
	if bool(result.get("changed", false)):
		_record_interaction_event("background_unlocked", content_id)
		_save_game()
		_refresh_progress_ui()
		if spine_background != null and spine_background.has_method("set_content_state"):
			spine_background.set_content_state(background_defs, unlocked_content)
			spine_background.load_selected_background()
		if store_controller != null:
			store_controller.refresh_items(_store_items())
			store_controller.show_status(localizer.translate("store.purchase_success"))
		return
	if store_controller == null:
		return
	var status := str(result.get("status", ""))
	if status == "insufficient":
		store_controller.show_status(localizer.trf("store.insufficient", {"focus_points": int(result.get("cost_focus_points", 0))}))
	elif status == "already_unlocked":
		store_controller.show_status(localizer.translate("store.already_unlocked"))
	else:
		store_controller.show_status(localizer.translate("store.purchase_failed"))


func _refresh_tasks_ui() -> void:
	if task_controller != null and task_controller.has_method("refresh_tasks"):
		task_controller.refresh_tasks()


func _refresh_progress_ui() -> void:
	fp_label.text = "FP"
	fp_label.tooltip_text = "%s: %d" % [localizer.translate("top.focus_points"), currencies.focus_points]
	level_label.text = "LV"
	level_label.tooltip_text = "%s %d  XP %d / %d" % [localizer.translate("top.focus_level"), level_progress.focus_level, level_progress.focus_xp, _xp_required_for_next_level()]
	bond_label.text = "BD"
	bond_label.tooltip_text = "%s Lv.%d  %d / %d" % [localizer.translate("top.bond"), bond_progress.bond_level, bond_progress.bond_points_current, _bond_required_for_next_level()]
	if unlocks_label != null:
		unlocks_label.tooltip_text = localizer.translate("top.unlocks")
	if store_button != null:
		store_button.text = "SH"
		store_button.tooltip_text = localizer.translate("store.title")
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
	SessionRewardCoordinator.update_focus_stats(daily_stats, session_mode, status, actual_sec)


func _format_time(seconds: int) -> String:
	var minutes := seconds / 60
	var secs := seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _status_title(status: String) -> String:
	return localizer.translate("timer.state_%s" % status)


func _reward_summary(rewards: Dictionary) -> String:
	return SessionRewardCoordinator.reward_summary(localizer, rewards)


func _result_summary(status: String, actual_sec: int, rewards: Dictionary, bond_level_up_text: String) -> String:
	return SessionRewardCoordinator.result_summary(
		localizer,
		planned_duration_sec,
		actual_sec,
		rewards,
		bond_level_up_text,
		_result_next_action_key(status)
	)


func _result_next_action_key(status: String) -> String:
	if status == "abandoned":
		return "result.next_action_retry"
	return "result.next_action_break"


func _bond_level_up_summary(level: int) -> String:
	if localizer != null:
		return localizer.trf("result.bond_level_up", {"level": level})
	return "Bond Level Up: Lv.%d" % level


func _task_status(task_id: String) -> String:
	if task_controller != null and task_controller.has_method("task_status"):
		return task_controller.task_status(task_id)
	return ""


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
	interaction_history = parsed.get("interaction_history", interaction_history)
	unlocked_content = parsed.get("unlocked_content", unlocked_content)
	var timer_settings = parsed.get("timer_settings", {})
	if typeof(timer_settings) == TYPE_DICTIONARY:
		duration_minutes = int(timer_settings.get("focus_minutes", duration_minutes))
		break_duration_minutes = int(timer_settings.get("break_minutes", break_duration_minutes))
		auto_restart_enabled = bool(timer_settings.get("auto_restart", auto_restart_enabled))
		alarm_enabled = bool(timer_settings.get("alarm", alarm_enabled))
	planned_duration_sec = duration_minutes * 60
	var music_state = parsed.get("music_state", {})
	if typeof(music_state) == TYPE_DICTIONARY:
		saved_music_path = str(music_state.get("current_path", saved_music_path))
		music_loop = bool(music_state.get("loop", music_loop))
		music_volume = float(music_state.get("volume", music_volume))
	var app_settings = parsed.get("app_settings", {})
	if typeof(app_settings) == TYPE_DICTIONARY:
		language_code = str(app_settings.get("language", language_code))
		break_media_enabled = bool(app_settings.get("break_media_enabled", break_media_enabled))
		break_media_path = str(app_settings.get("break_media_path", break_media_path))
		ambient_prompt_frequency = str(app_settings.get("ambient_prompt_frequency", ambient_prompt_frequency))
		if ambient_prompt_frequency != AMBIENT_PROMPT_LOW and ambient_prompt_frequency != AMBIENT_PROMPT_NORMAL and ambient_prompt_frequency != AMBIENT_PROMPT_OFF:
			ambient_prompt_frequency = AMBIENT_PROMPT_NORMAL


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
		"interaction_history": interaction_history,
		"unlocked_content": unlocked_content,
		"timer_settings": {
			"focus_minutes": duration_minutes,
			"break_minutes": break_duration_minutes,
			"auto_restart": auto_restart_enabled,
			"alarm": alarm_enabled
		},
		"music_state": current_music_state,
		"app_settings": {
			"language": language_code,
			"break_media_enabled": break_media_enabled,
			"break_media_path": break_media_path,
			"ambient_prompt_frequency": ambient_prompt_frequency
		}
	}
	SaveDataService.save_payload(SAVE_PATH, payload)
