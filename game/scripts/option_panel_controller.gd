extends Node

signal language_previous_pressed
signal language_next_pressed
signal break_media_pressed
signal break_media_path_pressed
signal ambient_prompt_pressed
signal music_autoplay_pressed
signal alarm_sound_pressed

var localizer
var option_button: Button
var option_panel: PanelContainer
var language_title: Label
var language_value: Label
var break_media_label: Label
var break_media_toggle: Button
var break_media_enabled := false
var break_media_path_label: Label
var break_media_path_button: Button
var break_media_path := ""
var ambient_prompt_label: Label
var ambient_prompt_button: Button
var ambient_prompt_frequency := "normal"
var music_autoplay_label: Label
var music_autoplay_toggle: Button
var music_autoplay_enabled := true
var alarm_sound_label: Label
var alarm_sound_button: Button
var alarm_sound_path := ""


func setup(parent: Control, localization_service, media_enabled: bool = false, ambient_frequency: String = "normal", autoplay_enabled: bool = true, media_path: String = "", alarm_path: String = "") -> Button:
	localizer = localization_service
	break_media_enabled = media_enabled
	ambient_prompt_frequency = ambient_frequency
	music_autoplay_enabled = autoplay_enabled
	break_media_path = media_path
	alarm_sound_path = alarm_path
	_build_option_panel(parent)
	refresh_text()
	return option_button


func toggle_visible() -> void:
	_raise_option_panel()
	option_panel.visible = not option_panel.visible


func hide() -> void:
	if option_panel != null:
		option_panel.visible = false


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
	if break_media_label != null:
		break_media_label.text = localizer.translate("option.break_media")
	if break_media_path_label != null:
		break_media_path_label.text = localizer.translate("option.break_media_path")
	if ambient_prompt_label != null:
		ambient_prompt_label.text = localizer.translate("option.ambient_prompt")
	if music_autoplay_label != null:
		music_autoplay_label.text = localizer.translate("option.music_autoplay")
	if alarm_sound_label != null:
		alarm_sound_label.text = localizer.translate("option.alarm_sound")
	refresh_ambient_prompt(ambient_prompt_frequency)
	refresh_break_media(break_media_enabled)
	refresh_break_media_path(break_media_path)
	refresh_music_autoplay(music_autoplay_enabled)
	refresh_alarm_sound(alarm_sound_path)


func refresh_break_media(enabled: bool) -> void:
	break_media_enabled = enabled
	if break_media_toggle == null:
		return
	break_media_toggle.tooltip_text = localizer.translate("settings.on") if enabled else localizer.translate("settings.off")
	break_media_toggle.add_theme_stylebox_override("normal", _new_switch_style(enabled))
	break_media_toggle.add_theme_stylebox_override("hover", _new_switch_style(enabled))
	break_media_toggle.add_theme_stylebox_override("pressed", _new_switch_style(enabled))
	var knob := break_media_toggle.get_node_or_null("SwitchKnob") as Control
	if knob == null:
		return
	knob.anchor_top = 0.5
	knob.anchor_bottom = 0.5
	knob.anchor_left = 1.0 if enabled else 0.0
	knob.anchor_right = 1.0 if enabled else 0.0
	knob.offset_left = -24 if enabled else 4
	knob.offset_right = -4 if enabled else 24
	knob.offset_top = -10
	knob.offset_bottom = 10


func refresh_break_media_path(path: String) -> void:
	break_media_path = path
	if break_media_path_button == null:
		return
	break_media_path_button.text = _display_path_name(break_media_path)
	break_media_path_button.tooltip_text = break_media_path


func refresh_alarm_sound(path: String) -> void:
	alarm_sound_path = path
	if alarm_sound_button == null:
		return
	alarm_sound_button.text = _display_path_name(alarm_sound_path)
	alarm_sound_button.tooltip_text = alarm_sound_path


func refresh_ambient_prompt(frequency: String) -> void:
	ambient_prompt_frequency = frequency
	if ambient_prompt_button == null:
		return
	ambient_prompt_button.text = localizer.translate("option.ambient_%s" % ambient_prompt_frequency)
	ambient_prompt_button.tooltip_text = localizer.translate("option.ambient_prompt")


func refresh_music_autoplay(enabled: bool) -> void:
	music_autoplay_enabled = enabled
	if music_autoplay_toggle == null:
		return
	music_autoplay_toggle.tooltip_text = localizer.translate("settings.on") if enabled else localizer.translate("settings.off")
	music_autoplay_toggle.add_theme_stylebox_override("normal", _new_switch_style(enabled))
	music_autoplay_toggle.add_theme_stylebox_override("hover", _new_switch_style(enabled))
	music_autoplay_toggle.add_theme_stylebox_override("pressed", _new_switch_style(enabled))
	var knob := music_autoplay_toggle.get_node_or_null("SwitchKnob") as Control
	if knob == null:
		return
	knob.anchor_top = 0.5
	knob.anchor_bottom = 0.5
	knob.anchor_left = 1.0 if enabled else 0.0
	knob.anchor_right = 1.0 if enabled else 0.0
	knob.offset_left = -24 if enabled else 4
	knob.offset_right = -4 if enabled else 24
	knob.offset_top = -10
	knob.offset_bottom = 10


func _build_option_panel(parent: Control) -> void:
	option_panel = _new_panel()
	option_panel.name = "OptionPanel"
	option_panel.visible = false
	option_panel.z_index = 100
	option_panel.anchor_left = 1.0
	option_panel.anchor_top = 0.0
	option_panel.anchor_right = 1.0
	option_panel.anchor_bottom = 0.0
	option_panel.offset_left = -330
	option_panel.offset_top = 54
	option_panel.offset_right = 0
	option_panel.offset_bottom = 378
	parent.add_child(option_panel)
	_raise_option_panel()

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

	var media_row := HBoxContainer.new()
	media_row.add_theme_constant_override("separation", 12)
	box.add_child(media_row)

	break_media_label = Label.new()
	break_media_label.custom_minimum_size = Vector2(210, 0)
	break_media_label.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	media_row.add_child(break_media_label)

	break_media_toggle = Button.new()
	break_media_toggle.text = ""
	break_media_toggle.custom_minimum_size = Vector2(54, 30)
	break_media_toggle.focus_mode = Control.FOCUS_NONE
	break_media_toggle.pressed.connect(func(): break_media_pressed.emit())
	var knob := Panel.new()
	knob.name = "SwitchKnob"
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", _new_switch_knob_style())
	break_media_toggle.add_child(knob)
	media_row.add_child(break_media_toggle)
	refresh_break_media(break_media_enabled)

	var media_path_row := HBoxContainer.new()
	media_path_row.add_theme_constant_override("separation", 12)
	box.add_child(media_path_row)

	break_media_path_label = Label.new()
	break_media_path_label.custom_minimum_size = Vector2(210, 0)
	break_media_path_label.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	media_path_row.add_child(break_media_path_label)

	break_media_path_button = Button.new()
	break_media_path_button.custom_minimum_size = Vector2(82, 30)
	break_media_path_button.focus_mode = Control.FOCUS_NONE
	break_media_path_button.pressed.connect(func(): break_media_path_pressed.emit())
	media_path_row.add_child(break_media_path_button)
	refresh_break_media_path(break_media_path)

	var ambient_row := HBoxContainer.new()
	ambient_row.add_theme_constant_override("separation", 12)
	box.add_child(ambient_row)

	ambient_prompt_label = Label.new()
	ambient_prompt_label.custom_minimum_size = Vector2(210, 0)
	ambient_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	ambient_row.add_child(ambient_prompt_label)

	ambient_prompt_button = Button.new()
	ambient_prompt_button.custom_minimum_size = Vector2(82, 30)
	ambient_prompt_button.focus_mode = Control.FOCUS_NONE
	ambient_prompt_button.pressed.connect(func(): ambient_prompt_pressed.emit())
	ambient_row.add_child(ambient_prompt_button)
	refresh_ambient_prompt(ambient_prompt_frequency)

	var autoplay_row := HBoxContainer.new()
	autoplay_row.add_theme_constant_override("separation", 12)
	box.add_child(autoplay_row)

	music_autoplay_label = Label.new()
	music_autoplay_label.custom_minimum_size = Vector2(210, 0)
	music_autoplay_label.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	autoplay_row.add_child(music_autoplay_label)

	music_autoplay_toggle = Button.new()
	music_autoplay_toggle.text = ""
	music_autoplay_toggle.custom_minimum_size = Vector2(54, 30)
	music_autoplay_toggle.focus_mode = Control.FOCUS_NONE
	music_autoplay_toggle.pressed.connect(func(): music_autoplay_pressed.emit())
	var autoplay_knob := Panel.new()
	autoplay_knob.name = "SwitchKnob"
	autoplay_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	autoplay_knob.add_theme_stylebox_override("panel", _new_switch_knob_style())
	music_autoplay_toggle.add_child(autoplay_knob)
	autoplay_row.add_child(music_autoplay_toggle)
	refresh_music_autoplay(music_autoplay_enabled)

	var alarm_row := HBoxContainer.new()
	alarm_row.add_theme_constant_override("separation", 12)
	box.add_child(alarm_row)

	alarm_sound_label = Label.new()
	alarm_sound_label.custom_minimum_size = Vector2(210, 0)
	alarm_sound_label.add_theme_color_override("font_color", Color(0.95, 0.0, 1.0, 1.0))
	alarm_row.add_child(alarm_sound_label)

	alarm_sound_button = Button.new()
	alarm_sound_button.custom_minimum_size = Vector2(82, 30)
	alarm_sound_button.focus_mode = Control.FOCUS_NONE
	alarm_sound_button.pressed.connect(func(): alarm_sound_pressed.emit())
	alarm_row.add_child(alarm_sound_button)
	refresh_alarm_sound(alarm_sound_path)


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


func _raise_option_panel() -> void:
	if option_panel == null:
		return
	var parent := option_panel.get_parent()
	if parent != null:
		parent.move_child(option_panel, parent.get_child_count() - 1)


func _new_switch_style(enabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.24, 0.85) if enabled else Color(0.08, 0.1, 0.18, 0.78)
	style.border_color = Color(1, 1, 1, 0.82)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	return style


func _new_switch_knob_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.94, 0.98, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _display_path_name(path: String) -> String:
	if path == "":
		return "-"
	return path.get_file()
