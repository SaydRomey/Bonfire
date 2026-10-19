# player.gd
extends CharacterBody3D
## Controls first-person movement, wood collection, and campfire preview placement.

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 18.0
@export var jump_velocity: float = 6.0
@export var campfire_cost: int = 3
@export var max_place_distance: float = 7.0

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var wood_count: int = 0
var look_rotation_x: float = 0.0
var placement_mode: bool = false
var placement_preview: BonfireCampfire = null
var current_place_position: Vector3 = Vector3.ZERO
var current_place_valid: bool = false

signal wood_changed(new_amount: int)


# Captures the cursor for first-person mouse control.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	wood_changed.emit(wood_count)


# Routes keyboard and mouse actions to interaction and placement systems.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotate_view(event.relative)

	#if event.is_action_pressed("ui_cancel"):
		#get_tree().quit()  # Esc quits the running game, even in placement mode.
		#return

	if event.is_action_pressed("place_campfire"):
		if placement_mode:
			_cancel_campfire_placement()
		else:
			_start_campfire_placement()
		return

	if event.is_action_pressed("cancel_place") and placement_mode:
		_cancel_campfire_placement()
		return

	if event.is_action_pressed("interact"):
		if placement_mode:
			_confirm_campfire_placement()
		else:
			_try_interact()
		return

	if event.is_action_pressed("confirm_place") and placement_mode:
		_confirm_campfire_placement()


# Applies gravity, moves the player, and updates the campfire preview.
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
	move_and_slide()

	if placement_mode:
		_update_campfire_preview()


# Rotates the player horizontally and clamps vertical camera pitch.
func _rotate_view(mouse_delta: Vector2) -> void:
	rotation.y -= mouse_delta.x * mouse_sensitivity
	look_rotation_x = clamp(
		look_rotation_x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(-80.0),
		deg_to_rad(80.0)
	)
	camera.rotation.x = look_rotation_x


# Updates vertical velocity and allows a jump while grounded.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity


# Converts WASD input into movement relative to the player's facing direction.
func _handle_movement() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis.x * input_dir.x + transform.basis.z * input_dir.y).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


# Sends an E-key interaction to the object in the camera ray.
func _try_interact() -> void:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return

	var collider := interaction_ray.get_collider()
	if collider != null and collider.has_method("interact"):
		collider.call("interact", self)


# Creates a collision-free campfire preview after checking the wood cost.
func _start_campfire_placement() -> void:
	if wood_count < campfire_cost:
		print("Need %d wood to place a campfire." % campfire_cost)
		return

	placement_mode = true
	current_place_valid = false
	placement_preview = BonfireCampfire.new()
	placement_preview.name = "CampfirePreview"
	placement_preview.is_preview = true  # Must be set before entering the scene tree.
	get_tree().current_scene.add_child(placement_preview)
	_update_campfire_preview()


# Moves the preview to the camera hit and marks unsuitable placement red.
func _update_campfire_preview() -> void:
	if placement_preview == null:
		return

	var hit := _get_camera_ground_hit()
	if hit.is_empty():
		current_place_valid = false
		placement_preview.visible = false
		return

	var hit_position: Vector3 = hit["position"]
	var hit_normal: Vector3 = hit["normal"]
	var hit_collider := hit["collider"] as Node

	current_place_position = hit_position + Vector3(0.0, 0.05, 0.0)
	var within_range := global_position.distance_to(hit_position) <= max_place_distance
	var gentle_slope := hit_normal.y >= 0.75
	var on_terrain := hit_collider != null and hit_collider.is_in_group("terrain")

	# Require a terrain hit so campfires cannot be placed on trees or rocks.
	current_place_valid = within_range and gentle_slope and on_terrain and wood_count >= campfire_cost
	placement_preview.visible = true
	placement_preview.global_position = current_place_position
	placement_preview.rotation.y = rotation.y
	placement_preview.set_preview_valid(current_place_valid)


# Casts a ray from the camera, excluding the player's own physics body.
func _get_camera_ground_hit() -> Dictionary:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * max_place_distance
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]  # Ray exclusions must contain physics RIDs, not Nodes.
	return get_world_3d().direct_space_state.intersect_ray(query)


# Creates the real campfire and deducts wood only after valid placement.
func _confirm_campfire_placement() -> void:
	if not placement_mode or not current_place_valid:
		return

	var campfire := BonfireCampfire.new()
	campfire.name = "Campfire"
	get_tree().current_scene.add_child(campfire)
	campfire.global_position = current_place_position
	campfire.rotation.y = rotation.y

	wood_count -= campfire_cost
	wood_changed.emit(wood_count)
	_cancel_campfire_placement()


# Removes the temporary preview without consuming resources.
func _cancel_campfire_placement() -> void:
	placement_mode = false
	current_place_valid = false
	if placement_preview != null:
		placement_preview.queue_free()
		placement_preview = null


# Adds wood from an interacted tree and informs the HUD.
func add_wood(amount: int) -> void:
	wood_count += amount
	wood_changed.emit(wood_count)
