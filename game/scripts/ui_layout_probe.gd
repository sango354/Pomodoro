extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CHECK_NODE_NAMES := ["LeftProgressHUD", "TopBar", "TaskPanel", "BottomModeControls"]


func _init() -> void:
	var errors := []
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	if scene == null:
		push_error("Missing %s" % MAIN_SCENE_PATH)
		quit(1)
		return
	var root: Node = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var nodes := {}
	for node_name in CHECK_NODE_NAMES:
		var node := _find_control(root, node_name)
		if node == null:
			errors.append("Missing UI node %s." % node_name)
			continue
		nodes[node_name] = node

	_check_no_overlap(nodes, "LeftProgressHUD", "TopBar", errors)
	_check_no_overlap(nodes, "LeftProgressHUD", "TaskPanel", errors)
	_check_no_overlap(nodes, "TopBar", "TaskPanel", errors)
	_check_top_bar_button_count(nodes, errors)

	if errors.is_empty():
		print("UI layout probe passed.")
		quit(0)
		return

	for error in errors:
		push_error(str(error))
		print("UI layout error: %s" % str(error))
	quit(1)


func _find_control(root: Node, node_name: String) -> Control:
	if root.name == node_name and root is Control:
		return root as Control
	for child in root.get_children():
		var found := _find_control(child, node_name)
		if found != null:
			return found
	return null


func _check_no_overlap(nodes: Dictionary, first_name: String, second_name: String, errors: Array) -> void:
	if not nodes.has(first_name) or not nodes.has(second_name):
		return
	var first := nodes[first_name] as Control
	var second := nodes[second_name] as Control
	var first_rect := first.get_global_rect()
	var second_rect := second.get_global_rect()
	if first_rect.intersects(second_rect):
		errors.append("%s overlaps %s. %s vs %s" % [first_name, second_name, str(first_rect), str(second_rect)])


func _check_top_bar_button_count(nodes: Dictionary, errors: Array) -> void:
	if not nodes.has("TopBar"):
		return
	var buttons := _collect_buttons(nodes["TopBar"])
	if buttons.size() != 5:
		errors.append("TopBar should have 5 icon buttons after removing Focus Points and Focus Level, found %d." % buttons.size())


func _collect_buttons(root: Node) -> Array:
	var buttons := []
	if root is Button:
		buttons.append(root)
	for child in root.get_children():
		buttons.append_array(_collect_buttons(child))
	return buttons
