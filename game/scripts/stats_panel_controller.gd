extends Node

signal mission_claim_requested(mission_id)

var localizer
var dismiss_layer: Button
var panel: PanelContainer
var title_label: Label
var stats_label: Label
var status_label: Label
var mission_list: VBoxContainer
var achievement_list: VBoxContainer
var current_stats := {}
var current_missions: Array = []
var current_achievements: Array = []


func setup(parent: Control, localization_service = null) -> void:
	localizer = localization_service
	_build_dismiss_layer(parent)
	_build_panel(parent)
	hide_panel()


func set_localizer(localization_service) -> void:
	localizer = localization_service
	refresh_text()


func show_panel(stats: Dictionary, missions: Array, achievements: Array) -> void:
	current_stats = stats
	current_missions = missions
	current_achievements = achievements
	_rebuild()
	panel.visible = true
	dismiss_layer.visible = true
	_raise_to_front()


func hide_panel() -> void:
	if panel != null:
		panel.visible = false
	if dismiss_layer != null:
		dismiss_layer.visible = false


func is_visible() -> bool:
	return panel != null and panel.visible


func refresh_panel(stats: Dictionary, missions: Array, achievements: Array) -> void:
	current_stats = stats
	current_missions = missions
	current_achievements = achievements
	if panel != null and panel.visible:
			_rebuild()


func show_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func refresh_text() -> void:
	if title_label != null:
		title_label.text = _tr("stats_panel.title")
	if panel != null and panel.visible:
		_rebuild()


func _build_dismiss_layer(parent: Control) -> void:
	dismiss_layer = Button.new()
	dismiss_layer.name = "StatsPanelDismissLayer"
	dismiss_layer.flat = true
	dismiss_layer.visible = false
	dismiss_layer.text = ""
	dismiss_layer.focus_mode = Control.FOCUS_NONE
	dismiss_layer.z_index = 180
	dismiss_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss_layer.pressed.connect(hide_panel)
	parent.add_child(dismiss_layer)


func _build_panel(parent: Control) -> void:
	panel = PanelContainer.new()
	panel.name = "StatsPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -420
	panel.offset_top = -260
	panel.offset_right = 420
	panel.offset_bottom = 260
	panel.z_index = 205
	panel.add_theme_stylebox_override("panel", _new_panel_style(0.84))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	title_label = _new_title(_tr("stats_panel.title"))
	root.add_child(title_label)

	stats_label = _new_muted_label("")
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats_label.add_theme_font_size_override("font_size", 13)
	root.add_child(stats_label)

	status_label = _new_muted_label("")
	status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.74, 0.95))
	root.add_child(status_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	mission_list = _build_column(columns, _tr("stats_panel.missions"))
	achievement_list = _build_column(columns, _tr("stats_panel.achievements"))


func _build_column(parent: Control, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 332)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func _rebuild() -> void:
	if title_label != null:
		title_label.text = _tr("stats_panel.title")
	stats_label.text = _stats_text()
	if status_label != null and status_label.text == "":
		status_label.text = _tr("stats_panel.hint")
	_rebuild_missions()
	_rebuild_achievements()


func _stats_text() -> String:
	return "%s: %d    %s: %d    %s: %d    %s: %d" % [
		_tr("stats.completed"),
		int(current_stats.get("completed_sessions", 0)),
		_tr("stats.partial"),
		int(current_stats.get("partial_sessions", 0)),
		_tr("stats.focus_minutes"),
		int(current_stats.get("focus_minutes_total", 0)),
		_tr("stats.tasks_done"),
		int(current_stats.get("tasks_completed", 0))
	]


func _rebuild_missions() -> void:
	_clear(mission_list)
	for item in current_missions:
		if typeof(item) == TYPE_DICTIONARY:
			mission_list.add_child(_build_item(item, true))


func _rebuild_achievements() -> void:
	_clear(achievement_list)
	for item in current_achievements:
		if typeof(item) == TYPE_DICTIONARY:
			achievement_list.add_child(_build_item(item, false))


func _build_item(item: Dictionary, claimable: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _new_item_style(str(item.get("status", "active"))))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var name := Label.new()
	name.text = str(item.get("name", ""))
	name.tooltip_text = name.text
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name)

	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = max(1, int(item.get("target", 1)))
	progress.value = int(item.get("progress", 0))
	progress.custom_minimum_size = Vector2(0, 14)
	box.add_child(progress)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	box.add_child(footer)

	var detail := _new_muted_label("%d / %d  %s" % [
		int(item.get("progress", 0)),
		int(item.get("target", 1)),
		_reward_text(item)
	])
	detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.add_theme_font_size_override("font_size", 12)
	detail.tooltip_text = detail.text
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(detail)

	if claimable:
		var button := Button.new()
		button.text = _tr("mission.claim")
		button.custom_minimum_size = Vector2(86, 28)
		button.disabled = str(item.get("status", "")) != "claimable"
		button.pressed.connect(func(): mission_claim_requested.emit(str(item.get("id", ""))))
		footer.add_child(button)
	else:
		var status := Label.new()
		status.text = _tr("achievement.unlocked") if str(item.get("status", "")) == "unlocked" else _tr("achievement.active")
		status.custom_minimum_size = Vector2(86, 0)
		status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		status.tooltip_text = status.text
		footer.add_child(status)
	return card


func _reward_text(item: Dictionary) -> String:
	return _trf("mission.reward", {
		"focus_points": int(item.get("reward_focus_points", 0)),
		"xp": int(item.get("reward_xp", 0)),
		"bond": int(item.get("reward_bond", 0))
	})


func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _raise_to_front() -> void:
	for node in [dismiss_layer, panel]:
		if node == null:
			continue
		var parent: Node = node.get_parent()
		if parent != null:
			parent.move_child(node, parent.get_child_count() - 1)


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


func _new_item_style(status: String) -> StyleBoxFlat:
	var style := _new_panel_style(0.42)
	if status == "claimable" or status == "unlocked":
		style.border_color = Color(0.55, 0.8, 0.66, 0.75)
	if status == "claimed":
		style.bg_color = Color(0.05, 0.07, 0.06, 0.5)
	return style


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


func _tr(key: String) -> String:
	if localizer != null:
		return localizer.translate(key)
	return key


func _trf(key: String, values: Dictionary) -> String:
	if localizer != null:
		return localizer.trf(key, values)
	var text := key
	for value_key in values.keys():
		text = text.replace("{%s}" % str(value_key), str(values[value_key]))
	return text
