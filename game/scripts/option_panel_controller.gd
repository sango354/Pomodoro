extends Node

signal language_previous_pressed
signal language_next_pressed

var localizer
var option_button: Button
var option_panel: PanelContainer
var language_title: Label
var language_value: Label


func setup(parent: Control, localization_service) -> Button:
	localizer = localization_service
	_build_option_panel(parent)
	refresh_text()
	return option_button


func toggle_visible() -> void:
	option_panel.visible = not option_panel.visible


func refresh_text() -> void:
	if localizer == null:
		return
	if option_button != null:
		option_button.text = localizer.translate("option.button")
		option_button.tooltip_text = localizer.translate("option.title")
	if language_title != null:
		language_title.text = localizer.translate("option.language")
	if language_value != null:
		language_value.text = localizer.language_name()


func _build_option_panel(parent: Control) -> void:
	option_panel = _new_panel()
	option_panel.name = "OptionPanel"
	option_panel.visible = false
	option_panel.anchor_left = 1.0
	option_panel.anchor_top = 0.0
	option_panel.anchor_right = 1.0
	option_panel.anchor_bottom = 0.0
	option_panel.offset_left = -330
	option_panel.offset_top = 54
	option_panel.offset_right = 0
	option_panel.offset_bottom = 148
	parent.add_child(option_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	option_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	language_title = Label.new()
	language_title.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	box.add_child(language_title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var previous := _new_arrow_button("<")
	previous.pressed.connect(func(): language_previous_pressed.emit())
	row.add_child(previous)

	language_value = Label.new()
	language_value.custom_minimum_size = Vector2(150, 30)
	language_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	language_value.add_theme_font_size_override("font_size", 18)
	language_value.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	row.add_child(language_value)

	var next := _new_arrow_button(">")
	next.pressed.connect(func(): language_next_pressed.emit())
	row.add_child(next)


func create_top_bar_button() -> Button:
	option_button = Button.new()
	option_button.custom_minimum_size = Vector2(42, 32)
	option_button.focus_mode = Control.FOCUS_NONE
	option_button.pressed.connect(toggle_visible)
	return option_button


func _new_arrow_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(40, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	return button


func _new_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _new_panel_style(0.72))
	return panel


func _new_panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.14, alpha)
	style.border_color = Color(1, 1, 1, 0.14)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
