extends Node2D

const ASSET_ROOT := "res://assets/spine/backgrounds"
const DEFAULT_VARIANT := "LofiBG_01_Nomal_Day"
const DEFAULT_ANIMATION := "Loop"
const TARGET_VIEWPORT_SIZE := Vector2(1152, 648)

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_spine_to_viewport)
	var variant := DEFAULT_VARIANT
	var skeleton_path := "%s/%s/%s.skel" % [ASSET_ROOT, variant, variant]
	var atlas_path := "%s/%s/%s.atlas" % [ASSET_ROOT, variant, variant]

	print("Checking spine-godot runtime classes...")
	print("SpineSprite: ", ClassDB.class_exists("SpineSprite"))
	print("SpineSkeletonFileResource: ", ClassDB.class_exists("SpineSkeletonFileResource"))
	print("SpineAtlasResource: ", ClassDB.class_exists("SpineAtlasResource"))
	print("SpineSkeletonDataResource: ", ClassDB.class_exists("SpineSkeletonDataResource"))
	print("Skeleton path exists: ", FileAccess.file_exists(skeleton_path))
	print("Atlas path exists: ", FileAccess.file_exists(atlas_path))
	print_spine_sprite_methods()

	if not ClassDB.class_exists("SpineSprite") or not ClassDB.class_exists("SpineSkeletonDataResource"):
		push_error("spine-godot runtime is not available in this Godot executable.")
		return

	var skeleton_res := ResourceLoader.load(skeleton_path)
	var atlas_res := ResourceLoader.load(atlas_path)
	print("Skeleton resource loaded: ", skeleton_res != null)
	print("Atlas resource loaded: ", atlas_res != null)

	if skeleton_res == null or atlas_res == null:
		push_error("Spine resources were not imported correctly.")
		return

	var skeleton_data_res := ClassDB.instantiate("SpineSkeletonDataResource") as Resource
	if skeleton_data_res == null:
		push_error("Unable to instantiate Spine skeleton data resource.")
		return
	skeleton_data_res.set("skeleton_file_res", skeleton_res)
	skeleton_data_res.set("atlas_res", atlas_res)

	var sprite := ClassDB.instantiate("SpineSprite") as Node
	if sprite == null:
		push_error("Unable to instantiate Spine sprite.")
		return
	sprite.name = "SpineBackground"
	sprite.set("skeleton_data_res", skeleton_data_res)
	add_child(sprite)
	print("SpineSprite instantiated: ", sprite != null)
	print_spine_debug_info(sprite)

	_play_first_animation(sprite)
	_fit_spine_to_viewport()

	# The current source atlases declare pma:true. Official spine-godot docs say
	# PMA atlases are not supported, so this probe verifies runtime setup only.
	print("Runtime is installed. Re-export these Spine assets without PMA before final import.")


func print_spine_debug_info(sprite: Node) -> void:
	var skeleton = sprite.get_skeleton()
	if skeleton == null:
		push_warning("Spine skeleton is not available yet; skipping debug info.")
		return
	var skeleton_data = skeleton.get_data()
	if skeleton_data == null:
		push_warning("Spine skeleton data is not available yet; skipping debug info.")
		return
	var animation_names: Array[String] = []
	for animation in skeleton_data.get_animations():
		animation_names.append(animation.get_name())
	print("Available animations: ", animation_names)


func _play_first_animation(sprite: Node) -> void:
	var skeleton = sprite.get_skeleton()
	if skeleton == null:
		push_warning("Spine skeleton is not available yet; skipping animation playback.")
		return
	var skeleton_data = skeleton.get_data()
	if skeleton_data == null:
		push_warning("Spine skeleton data is not available yet; skipping animation playback.")
		return
	var animations: Array = skeleton_data.get_animations()
	if animations.is_empty():
		push_warning("No animations found in Spine skeleton.")
		return

	var animation_name: String = animations[0].get_name()
	for animation in animations:
		if animation.get_name() == DEFAULT_ANIMATION:
			animation_name = DEFAULT_ANIMATION
			break
	var animation_state = sprite.get_animation_state()
	if animation_state == null:
		push_warning("Spine animation state is not available yet; skipping animation playback.")
		return
	animation_state.set_animation(animation_name, true, 0)
	print("Playing loop animation: ", animation_name)


func _fit_spine_to_viewport() -> void:
	var sprite := get_node_or_null("SpineBackground")
	if sprite == null:
		return

	var viewport_size := Vector2(get_viewport_rect().size)
	if viewport_size.x <= 0 or viewport_size.y <= 0 or viewport_size.x == viewport_size.y:
		viewport_size = TARGET_VIEWPORT_SIZE

	var skeleton = sprite.get_skeleton()
	if skeleton == null:
		push_warning("Spine skeleton is not available yet; using provisional fit.")
		sprite.scale = Vector2.ONE * 0.55
		sprite.position = Vector2(215, 30)
		return
	skeleton.update_world_transform()

	if not sprite.has_method("_edit_get_rect"):
		push_warning("SpineSprite bounds API is unavailable in this runtime; using provisional fit.")
		sprite.scale = Vector2.ONE * 0.55
		sprite.position = Vector2(215, 30)
		return

	var bounds: Rect2 = sprite.call("_edit_get_rect")
	var size := Vector2(bounds.size.x, bounds.size.y)
	if size.x <= 0 or size.y <= 0:
		push_warning("Could not determine Spine bounds for camera fitting.")
		return

	var scale_factor: float = min(viewport_size.x / size.x, viewport_size.y / size.y) * 0.98
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = viewport_size * 0.5 - (Vector2(bounds.position.x, bounds.position.y) + size * 0.5) * scale_factor
	print("Fitted Spine bounds: position=", bounds.position, " size=", bounds.size, " scale=", scale_factor, " viewport=", viewport_size)


func print_spine_sprite_methods() -> void:
	var interesting: Array[String] = []
	for method in ClassDB.class_get_method_list("SpineSprite"):
		var method_name: String = method.name
		if method_name.contains("bound") or method_name.contains("rect") or method_name.contains("animation") or method_name.contains("skeleton"):
			interesting.append(method_name)
	print("SpineSprite relevant methods: ", interesting)
