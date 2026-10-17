# player.gd
extends CharacterBody3D

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
var placement_preview: StaticBody3D = null
var current_place_position: Vector3 = Vector3.ZERO
var current_place_valid: bool = false

signal wood_changed(new_amount: int)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	emit_signal("wood_changed", wood_count)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotate_view(event.relative)

	if event.is_action_pressed("ui_cancel"):
		if placement_mode:
			_cancel_campfire_placement()
		elif Input.MOUSE_MODE_VISIBLE:
			get_tree().quit()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("interact"):
		if placement_mode:
			_confirm_campfire_placement()
		else:
			_try_interact()

	if event.is_action_pressed("place_campfire"):
		if placement_mode:
			_cancel_campfire_placement()
		else:
			_start_campfire_placement()

	if event.is_action_pressed("confirm_place"):
		if placement_mode:
			_confirm_campfire_placement()

	if event.is_action_pressed("cancel_place"):
		if placement_mode:
			_cancel_campfire_placement()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()

	if placement_mode:
		_update_campfire_preview()

	move_and_slide()


func _rotate_view(mouse_delta: Vector2) -> void:
	rotation.y -= mouse_delta.x * mouse_sensitivity

	look_rotation_x -= mouse_delta.y * mouse_sensitivity
	look_rotation_x = clamp(look_rotation_x, deg_to_rad(-80), deg_to_rad(80))

	camera.rotation.x = look_rotation_x


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity


func _handle_movement() -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction := Vector3.ZERO
	direction += transform.basis.z * input_dir.y
	direction += transform.basis.x * input_dir.x
	direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var collider := interaction_ray.get_collider()

	if collider == null:
		return

	if collider.has_method("interact"):
		collider.interact(self)


func _start_campfire_placement() -> void:
	if wood_count < campfire_cost:
		print("Need at least %d wood to place a campfire." % campfire_cost)
		return

	placement_mode = true
	current_place_valid = false

	placement_preview = StaticBody3D.new()
	placement_preview.name = "CampfirePreview"
	placement_preview.set_script(preload("res://scripts/campfire.gd"))
	placement_preview.is_preview = true

	get_tree().current_scene.add_child(placement_preview)

	_update_campfire_preview()


func _update_campfire_preview() -> void:
	if placement_preview == null:
		return

	var result := _get_camera_ground_hit()

	if result.is_empty():
		current_place_valid = false
		placement_preview.visible = false
		placement_preview.set_preview_valid(false)
		return

	placement_preview.visible = true

	var hit_position: Vector3 = result["position"]
	var hit_normal: Vector3 = result["normal"]

	current_place_position = hit_position
	current_place_position.y += 0.05

	var distance_from_player := global_position.distance_to(current_place_position)

	current_place_valid = true

	if distance_from_player > max_place_distance:
		current_place_valid = false

	if hit_normal.y < 0.75:
		current_place_valid = false

	if wood_count < campfire_cost:
		current_place_valid = false

	placement_preview.global_position = current_place_position
	placement_preview.rotation.y = rotation.y
	placement_preview.set_preview_valid(current_place_valid)


func _get_camera_ground_hit() -> Dictionary:
	var space_state := get_world_3d().direct_space_state

	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * max_place_distance)

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	return result


func _confirm_campfire_placement() -> void:
	if not placement_mode:
		return

	if not current_place_valid:
		print("Cannot place campfire here.")
		return

	var campfire := StaticBody3D.new()
	campfire.name = "Campfire"
	campfire.set_script(preload("res://scripts/campfire.gd"))
	campfire.is_preview = false

	get_tree().current_scene.add_child(campfire)
	campfire.global_position = current_place_position
	campfire.rotation.y = rotation.y

	wood_count -= campfire_cost
	emit_signal("wood_changed", wood_count)

	_cancel_campfire_placement()


func _cancel_campfire_placement() -> void:
	placement_mode = false
	current_place_valid = false

	if placement_preview != null:
		placement_preview.queue_free()
		placement_preview = null


func add_wood(amount: int) -> void:
	wood_count += amount
	emit_signal("wood_changed", wood_count)
