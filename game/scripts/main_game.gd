extends Node

const SAVE_PATH := "user://save.json"
const ASSET_ROOT := "res://assets/spine/backgrounds"
const TARGET_VIEWPORT_SIZE := Vector2(1152, 648)
const HUD_MAX_WIDTH := 390
const SIDE_PANEL_MAX_WIDTH := 300
const MIN_REWARDABLE_SESSION_SEC := 300
const BASE_FOCUS_POINTS := 20
const BASE_BOND := 10
const BASE_XP := 30
const TASK_BONUS_FOCUS_POINTS := 8
const TASK_BONUS_XP := 10

var app_state := "idle"
var session_mode := "focus"
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
var phase_label: Label
var task_label: Label
var message_label: Label
var fp_label: Label
var level_label: Label
var bond_label: Label
var stats_label: Label
var progress_bar: ProgressBar
var task_input: LineEdit
var task_select: OptionButton
var duration_minutes := 25
var duration_value_label: Label
var start_button: Button
var pause_button: Button
var end_button: Button
var task_list: VBoxContainer
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
	overlay.color = Color(0.04, 0.045, 0.05, 0.28)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	app_container.add_child(overlay)

	var margins := MarginContainer.new()
	margins.name = "LayoutMargins"
	margins.set_anchors_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_top", 22)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_bottom", 22)
	app_container.add_child(margins)

	var layers := Control.new()
	layers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margins.add_child(layers)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(HUD_MAX_WIDTH, 0)
	left.size = Vector2(HUD_MAX_WIDTH, 0)
	left.anchor_left = 0.0
	left.anchor_top = 0.0
	left.anchor_right = 0.0
	left.anchor_bottom = 0.0
	left.offset_left = 0
	left.offset_top = 0
	left.offset_right = HUD_MAX_WIDTH
	left.offset_bottom = 450
	left.add_theme_constant_override("separation", 8)
	layers.add_child(left)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(SIDE_PANEL_MAX_WIDTH, 0)
	right.size = Vector2(SIDE_PANEL_MAX_WIDTH, 0)
	right.anchor_left = 1.0
	right.anchor_top = 0.0
	right.anchor_right = 1.0
	right.anchor_bottom = 0.0
	right.offset_left = -SIDE_PANEL_MAX_WIDTH
	right.offset_top = 0
	right.offset_right = 0
	right.offset_bottom = 420
	right.add_theme_constant_override("separation", 8)
	layers.add_child(right)

	_build_timer_panel(left)
	_build_progress_panel(left)
	_build_result_panel(left)
	_build_task_panel(right)
	_build_stats_panel(right)


func _build_timer_panel(parent: VBoxContainer) -> void:
	var panel := _new_panel()
	panel.custom_minimum_size = Vector2(HUD_MAX_WIDTH, 316)
	parent.add_child(panel)
	var box := _panel_box(panel)
	box.add_child(_new_title("Lo-fi Focus"))

	phase_label = _new_muted_label("")
	box.add_child(phase_label)

	timer_label = Label.new()
	timer_label.text = "25:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 50)
	box.add_child(timer_label)

	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	box.add_child(progress_bar)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	box.add_child(preset_row)
	for minutes in [15, 25, 45]:
		var preset := Button.new()
		preset.text = "%d" % minutes
		preset.custom_minimum_size = Vector2(54, 32)
		preset.pressed.connect(_set_duration_minutes.bind(minutes))
		preset_row.add_child(preset)

	var duration_row := HBoxContainer.new()
	duration_row.add_theme_constant_override("separation", 8)
	box.add_child(duration_row)
	var focus_label := _new_muted_label("Focus")
	focus_label.custom_minimum_size = Vector2(58, 32)
	duration_row.add_child(focus_label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(36, 32)
	minus_button.pressed.connect(_adjust_duration_minutes.bind(-5))
	duration_row.add_child(minus_button)

	duration_value_label = _new_muted_label("")
	duration_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration_value_label.custom_minimum_size = Vector2(82, 32)
	duration_row.add_child(duration_value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(36, 32)
	plus_button.pressed.connect(_adjust_duration_minutes.bind(5))
	duration_row.add_child(plus_button)

	task_select = OptionButton.new()
	task_select.custom_minimum_size = Vector2(0, 32)
	task_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(task_select)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	box.add_child(controls)

	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(76, 32)
	start_button.pressed.connect(_on_start_pressed)
	controls.add_child(start_button)

	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(76, 32)
	pause_button.pressed.connect(_on_pause_pressed)
	controls.add_child(pause_button)

	end_button = Button.new()
	end_button.text = "End"
	end_button.custom_minimum_size = Vector2(76, 32)
	end_button.pressed.connect(_on_end_pressed)
	controls.add_child(end_button)

	task_label = _new_muted_label("")
	box.add_child(task_label)
	message_label = _new_muted_label("")
	box.add_child(message_label)


func _build_result_panel(parent: VBoxContainer) -> void:
	result_panel = _new_panel()
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
	mark_task_done_button.pressed.connect(_on_mark_bound_task_done)
	buttons.add_child(mark_task_done_button)

	break_button = Button.new()
	break_button.text = "Start Break"
	break_button.pressed.connect(_on_break_pressed)
	buttons.add_child(break_button)


func _build_progress_panel(parent: VBoxContainer) -> void:
	var panel := _new_panel()
	parent.add_child(panel)
	var box := _panel_box(panel)
	box.add_child(_new_title("Progress"))
	fp_label = _new_muted_label("")
	level_label = _new_muted_label("")
	bond_label = _new_muted_label("")
	box.add_child(fp_label)
	box.add_child(level_label)
	box.add_child(bond_label)


func _build_task_panel(parent: VBoxContainer) -> void:
	var panel := _new_panel()
	parent.add_child(panel)
	var box := _panel_box(panel)
	box.add_child(_new_title("Tasks"))

	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 8)
	box.add_child(add_row)
	task_input = LineEdit.new()
	task_input.placeholder_text = "New task"
	task_input.custom_minimum_size = Vector2(0, 32)
	task_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task_input.text_submitted.connect(_on_task_submitted)
	add_row.add_child(task_input)

	var add_button := Button.new()
	add_button.text = "+"
	add_button.custom_minimum_size = Vector2(36, 32)
	add_button.pressed.connect(_on_add_task_pressed)
	add_row.add_child(add_button)

	task_list = VBoxContainer.new()
	task_list.add_theme_constant_override("separation", 6)
	box.add_child(task_list)


func _build_stats_panel(parent: VBoxContainer) -> void:
	var panel := _new_panel()
	parent.add_child(panel)
	var box := _panel_box(panel)
	box.add_child(_new_title("Today"))
	stats_label = _new_muted_label("")
	box.add_child(stats_label)


func _new_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.068, 0.62)
	style.border_color = Color(1, 1, 1, 0.14)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


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


func _new_muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9, 0.92))
	return label


func _on_start_pressed() -> void:
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


func _on_pause_pressed() -> void:
	if app_state == "running":
		app_state = "paused"
		pause_button.text = "Resume"
		message_label.text = "Paused"
	elif app_state == "paused":
		app_state = "running"
		pause_button.text = "Pause"
		message_label.text = "Back in focus"
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
	planned_duration_sec = 5 * 60
	elapsed_sec = 0.0
	active_task_id = ""
	app_state = "running"
	message_label.text = "Take a short break."
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
	_create_task(task_input.text)


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
	task_input.text = ""
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
	var index := task_select.selected
	if index < 0:
		return ""
	var metadata = task_select.get_item_metadata(index)
	return str(metadata)


func _refresh_all() -> void:
	_refresh_timer_ui()
	_refresh_tasks_ui()
	_refresh_progress_ui()
	_refresh_controls()


func _refresh_timer_ui() -> void:
	var remaining: int = max(planned_duration_sec - int(elapsed_sec), 0)
	timer_label.text = _format_time(remaining)
	progress_bar.value = 100.0 * elapsed_sec / float(max(planned_duration_sec, 1))
	duration_value_label.text = "%d min" % duration_minutes
	var mode_text := "Focus" if session_mode == "focus" else "Short Break"
	phase_label.text = "%s - %s" % [mode_text, app_state.capitalize()]
	task_label.text = "Task: %s" % _task_title(active_task_id) if active_task_id != "" else "Task: none"


func _refresh_controls() -> void:
	var can_configure := app_state != "running" and app_state != "paused"
	task_select.disabled = not can_configure
	start_button.disabled = app_state == "running"
	pause_button.disabled = app_state != "running" and app_state != "paused"
	end_button.disabled = app_state != "running" and app_state != "paused"
	pause_button.text = "Resume" if app_state == "paused" else "Pause"
	result_panel.visible = app_state == "completed" or app_state == "partial" or app_state == "abandoned"
	mark_task_done_button.disabled = active_task_id == "" or _task_status(active_task_id) == "done"
	break_button.disabled = app_state == "abandoned"


func _set_duration_minutes(minutes: int) -> void:
	if app_state == "running" or app_state == "paused":
		return
	duration_minutes = clamp(minutes, 1, 180)
	planned_duration_sec = duration_minutes * 60
	_refresh_timer_ui()


func _adjust_duration_minutes(delta_minutes: int) -> void:
	_set_duration_minutes(duration_minutes + delta_minutes)


func _refresh_tasks_ui() -> void:
	task_select.clear()
	task_select.add_item("No task")
	task_select.set_item_metadata(0, "")
	var item_index := 1
	for task in tasks:
		if task.status == "todo" or task.status == "in_progress":
			task_select.add_item(task.title)
			task_select.set_item_metadata(item_index, task.task_id)
			if task.task_id == active_task_id:
				task_select.select(item_index)
			item_index += 1

	for child in task_list.get_children():
		child.queue_free()

	for task in tasks:
		if task.status == "archived":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		task_list.add_child(row)

		var title := Label.new()
		title.text = "%s  [%s]" % [task.title, task.status]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.clip_text = true
		row.add_child(title)

		var done := Button.new()
		done.text = "Done"
		done.custom_minimum_size = Vector2(54, 30)
		done.disabled = task.status == "done"
		done.pressed.connect(_complete_task.bind(task.task_id))
		row.add_child(done)

		var archive := Button.new()
		archive.text = "Archive"
		archive.custom_minimum_size = Vector2(70, 30)
		archive.pressed.connect(_archive_task.bind(task.task_id))
		row.add_child(archive)


func _refresh_progress_ui() -> void:
	fp_label.text = "Focus Points: %d" % currencies.focus_points
	level_label.text = "Level %d  XP %d / %d" % [level_progress.focus_level, level_progress.focus_xp, _xp_required_for_next_level()]
	bond_label.text = "Bond Lv.%d  %d / %d" % [bond_progress.bond_level, bond_progress.bond_points_current, _bond_required_for_next_level()]
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
