extends Node

signal background_selected(background_id)
signal store_requested

var localizer
var dismiss_layer: Button
var panel: PanelContainer
var title_label: Label
var item_list: VBoxContainer
var selected_background_id := ""
var current_items: Array = []


func setup(parent: Control, localization_service = null) -> void:
	localizer = localization_service
	_build_dismiss_layer(parent)
	_build_panel(parent)
	hide_inventory()


func set_localizer(localization_service) -> void:
	localizer = localization_service
	refresh_text()


func show_inventory(items: Array, equipped_background_id: String) -> void:
	current_items = items
	selected_background_id = equipped_background_id
	_rebuild_items()
	panel.visible = true
	dismiss_layer.visible = true
	_raise_to_front()


func hide_inventory() -> void:
	if panel != null:
		panel.visible = false
	if dismiss_layer != null:
		dismiss_layer.visible = false


func is_inventory_visible() -> bool:
	return panel != null and panel.visible


func refresh_items(items: Array, equipped_background_id: String) -> void:
	current_items = items
	selected_background_id = equipped_background_id
	if panel != null and panel.visible:
		_rebuild_items()


func refresh_text() -> void:
	if title_label != null:
		title_label.text = _tr("inventory.title")
	if panel != null and panel.visible:
		_rebuild_items()


func _build_dismiss_layer(parent: Control) -> void:
	dismiss_layer = Button.new()
	dismiss_layer.name = "InventoryDismissLayer"
	dismiss_layer.flat = true
	dismiss_layer.visible = false
	dismiss_layer.text = ""
	dismiss_layer.focus_mode = Control.FOCUS_NONE
	dismiss_layer.z_index = 180
	dismiss_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss_layer.pressed.connect(hide_inventory)
	parent.add_child(dismiss_layer)


func _build_panel(parent: Control) -> void:
	panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_top = -230
	panel.offset_right = 250
	panel.offset_bottom = 230
	panel.z_index = 205
	panel.add_theme_stylebox_override("panel", _new_panel_style(0.82))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	title_label = Label.new()
	title_label.text = _tr("inventory.title")
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var store_button := Button.new()
	store_button.text = _tr("inventory.open_store")
	store_button.custom_minimum_size = Vector2(96, 32)
	store_button.pressed.connect(_request_store)
	header.add_child(store_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 8)
	scroll.add_child(item_list)


func _rebuild_items() -> void:
	for child in item_list.get_children():
		child.queue_free()
	if current_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = _tr("inventory.empty")
		item_list.add_child(empty_label)
		return
	for item in current_items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		item_list.add_child(_build_item_row(item))


func _build_item_row(item: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", _new_item_style(bool(item.get("equipped", false))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	row_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	row.add_child(_thumbnail_or_swatch(item, Vector2(72, 42)))

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = str(item.get("name", ""))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_box.add_child(name_label)

	var status_label := Label.new()
	status_label.text = _status_text(item)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.86, 0.9))
	text_box.add_child(status_label)

	var equip_button := Button.new()
	equip_button.custom_minimum_size = Vector2(92, 32)
	equip_button.disabled = bool(item.get("locked", false)) or bool(item.get("equipped", false))
	equip_button.text = _tr("inventory.equipped") if bool(item.get("equipped", false)) else _tr("inventory.equip")
	equip_button.pressed.connect(_select_background.bind(str(item.get("id", ""))))
	row.add_child(equip_button)
	return row_panel


func _status_text(item: Dictionary) -> String:
	if bool(item.get("equipped", false)):
		return _tr("inventory.status_equipped")
	if bool(item.get("locked", false)):
		return "%s - %s" % [_tr("inventory.status_locked"), _trf("store.cost", {"focus_points": int(item.get("cost_focus_points", 0))})]
	if bool(item.get("auto", false)):
		return _tr("inventory.status_auto")
	return _tr("inventory.status_unlocked")


func _select_background(background_id: String) -> void:
	if background_id == "":
		return
	hide_inventory()
	background_selected.emit(background_id)


func _request_store() -> void:
	hide_inventory()
	store_requested.emit()


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


func _new_item_style(equipped: bool) -> StyleBoxFlat:
	var style := _new_panel_style(0.42)
	if equipped:
		style.border_color = Color(0.55, 0.8, 0.66, 0.75)
		style.bg_color = Color(0.08, 0.12, 0.1, 0.72)
	return style


func _swatch_color(background_id: String, locked: bool) -> Color:
	if locked:
		return Color(0.16, 0.16, 0.17, 0.95)
	if background_id == "lofi_auto":
		return Color(0.24, 0.35, 0.42, 0.95)
	if background_id.contains("good"):
		return Color(0.42, 0.34, 0.2, 0.95)
	if background_id.contains("troubled"):
		return Color(0.28, 0.24, 0.34, 0.95)
	if background_id.contains("room"):
		return Color(0.30, 0.28, 0.24, 0.95)
	return Color(0.24, 0.30, 0.28, 0.95)


func _thumbnail_or_swatch(item: Dictionary, size: Vector2) -> Control:
	var path := str(item.get("thumbnail_path", ""))
	var thumbnail := _load_thumbnail_texture(path)
	if thumbnail != null:
		var texture_rect := TextureRect.new()
		texture_rect.custom_minimum_size = size
		texture_rect.texture = thumbnail
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture_rect.modulate = Color(0.45, 0.45, 0.45, 1.0) if bool(item.get("locked", false)) else Color.WHITE
		return texture_rect
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = size
	swatch.color = _swatch_color(str(item.get("id", "")), bool(item.get("locked", false)))
	return swatch


func _load_thumbnail_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


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
