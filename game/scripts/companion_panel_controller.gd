extends Node

const CompanionDialogueService = preload("res://scripts/companion_dialogue_service.gd")

var companion_panel: PanelContainer
var companion_dialogue_label: Label
var title_label: Label
var next_button: Button
var skip_button: Button
var break_dialogue_index := 0
var localizer


func setup(parent: Control, localization_service = null) -> void:
	localizer = localization_service
	_build_companion_panel(parent)


func show_break_interaction() -> void:
	if companion_panel == null:
		return
	var text_key := CompanionDialogueService.break_dialogue_key(break_dialogue_index)
	companion_dialogue_label.text = _tr(text_key) if text_key != "" else CompanionDialogueService.break_dialogue_text(break_dialogue_index)
	companion_panel.visible = true


func hide_break_interaction() -> void:
	if companion_panel != null:
		companion_panel.visible = false


func _show_next_break_dialogue() -> void:
	break_dialogue_index += 1
	show_break_interaction()


func set_localizer(localization_service) -> void:
	localizer = localization_service
	if title_label != null:
		title_label.text = _tr("companion.break_title")
	if next_button != null:
		next_button.text = _tr("companion.next")
	if skip_button != null:
		skip_button.text = _tr("companion.skip")
	if companion_panel != null and companion_panel.visible:
		show_break_interaction()


func _build_companion_panel(parent: Control) -> void:
	companion_panel = _new_panel()
	companion_panel.name = "BreakCompanionPanel"
	companion_panel.visible = false
	companion_panel.anchor_left = 0.5
	companion_panel.anchor_top = 1.0
	companion_panel.anchor_right = 0.5
	companion_panel.anchor_bottom = 1.0
	companion_panel.offset_left = -220
	companion_panel.offset_top = -220
	companion_panel.offset_right = 220
	companion_panel.offset_bottom = -72
	parent.add_child(companion_panel)

	var box := _panel_box(companion_panel)
	title_label = _new_title(_tr("companion.break_title"))
	box.add_child(title_label)
	companion_dialogue_label = _new_muted_label("")
	companion_dialogue_label.custom_minimum_size = Vector2(0, 54)
	box.add_child(companion_dialogue_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	next_button = Button.new()
	next_button.text = _tr("companion.next")
	next_button.custom_minimum_size = Vector2(84, 30)
	next_button.pressed.connect(_show_next_break_dialogue)
	buttons.add_child(next_button)

	skip_button = Button.new()
	skip_button.text = _tr("companion.skip")
	skip_button.custom_minimum_size = Vector2(84, 30)
	skip_button.pressed.connect(hide_break_interaction)
	buttons.add_child(skip_button)


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
