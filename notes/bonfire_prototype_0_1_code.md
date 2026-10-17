# Bonfire Game Prototype 0.1 — Required Godot Files

This document contains the required setup and script files for the first playable prototype of the campfire/forest game.

The goal of this step is to create a minimal Godot 4 prototype with:

```text
- First-person walking
- Mouse-look camera
- Procedural forest object placement
- Trees and rocks
- Interact with trees to collect wood
- Place a basic campfire object
- Simple UI showing wood count
```

Recommended project structure:

```text
res://
├── scenes/
│   └── main.tscn
└── scripts/
    ├── player.gd
    ├── world_generator.gd
    ├── resource_node.gd
    ├── campfire.gd
    └── hud.gd
```

---

## 1. `res://scenes/main.tscn`

Create this scene manually in Godot.

Scene tree:

```text
Main
├── World
│   ├── Ground
│   ├── GeneratedObjects
│   └── WorldGenerator
├── Player
│   ├── CollisionShape3D
│   └── Camera3D
│       └── InteractionRay
├── HUD
│   └── WoodLabel
└── Sun
```

Node types:

```text
Main: Node3D
World: Node3D
Ground: StaticBody3D
GeneratedObjects: Node3D
WorldGenerator: Node
Player: CharacterBody3D
CollisionShape3D: CollisionShape3D
Camera3D: Camera3D
InteractionRay: RayCast3D
HUD: CanvasLayer
WoodLabel: Label
Sun: DirectionalLight3D
```

Attach scripts:

```text
Player -> res://scripts/player.gd
WorldGenerator -> res://scripts/world_generator.gd
HUD -> res://scripts/hud.gd
```

For `Ground`, add:

```text
Ground
├── CollisionShape3D
└── MeshInstance3D
```

Use a `BoxShape3D` for the collision shape.

Use a `BoxMesh` for the mesh.

Suggested settings:

```text
Ground position: (0, -0.5, 0)
Ground scale: (100, 1, 100)
```

For `InteractionRay`:

```text
enabled: true
target_position: (0, 0, -4)
```

Make sure `InteractionRay` is a child of `Camera3D`, not directly under `Player`.

Correct Player subtree:

```text
Player
├── CollisionShape3D
└── Camera3D
    └── InteractionRay
```

---

## 2. `res://scripts/player.gd`

```gdscript
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 18.0
@export var jump_velocity: float = 6.0

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var wood_count: int = 0
var look_rotation_x: float = 0.0

signal wood_changed(new_amount: int)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	emit_signal("wood_changed", wood_count)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotate_view(event.relative)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("place_campfire"):
		_try_place_campfire()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
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
	direction += -transform.basis.z * input_dir.y
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


func _try_place_campfire() -> void:
	var cost := 3

	if wood_count < cost:
		print("Need at least %d wood to place a campfire." % cost)
		return

	var campfire_scene := preload("res://scripts/campfire.gd")

	var campfire := StaticBody3D.new()
	campfire.set_script(campfire_scene)

	var forward := -transform.basis.z.normalized()
	var place_position := global_position + forward * 3.0
	place_position.y = 0.05

	get_tree().current_scene.add_child(campfire)
	campfire.global_position = place_position

	wood_count -= cost
	emit_signal("wood_changed", wood_count)


func add_wood(amount: int) -> void:
	wood_count += amount
	emit_signal("wood_changed", wood_count)
```

---

## 3. `res://scripts/world_generator.gd`

```gdscript
extends Node

@export var world_size: float = 80.0
@export var tree_count: int = 120
@export var rock_count: int = 45
@export var seed_value: int = 12345

@onready var generated_objects: Node3D = $"../GeneratedObjects"

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = seed_value
	generate_world()


func generate_world() -> void:
	_clear_generated_objects()

	for i in tree_count:
		var position := _random_world_position()
		_spawn_tree(position)

	for i in rock_count:
		var position := _random_world_position()
		_spawn_rock(position)


func _clear_generated_objects() -> void:
	for child in generated_objects.get_children():
		child.queue_free()


func _random_world_position() -> Vector3:
	var half_size := world_size * 0.5

	return Vector3(
		rng.randf_range(-half_size, half_size),
		0.0,
		rng.randf_range(-half_size, half_size)
	)


func _spawn_tree(position: Vector3) -> void:
	var tree := StaticBody3D.new()
	tree.name = "Tree"
	tree.set_script(preload("res://scripts/resource_node.gd"))
	tree.resource_type = "wood"
	tree.resource_amount = 1

	generated_objects.add_child(tree)
	tree.global_position = position

	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 3.0

	trunk.mesh = trunk_mesh
	trunk.position.y = 1.5

	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.35, 0.18, 0.08)
	trunk.material_override = trunk_material

	tree.add_child(trunk)

	var leaves := MeshInstance3D.new()
	leaves.name = "Leaves"

	var leaves_mesh := SphereMesh.new()
	leaves_mesh.radius = 1.2
	leaves_mesh.height = 1.8

	leaves.mesh = leaves_mesh
	leaves.position.y = 3.1

	var leaves_material := StandardMaterial3D.new()
	leaves_material.albedo_color = Color(0.08, 0.35, 0.12)
	leaves.material_override = leaves_material

	tree.add_child(leaves)

	var collision := CollisionShape3D.new()
	var collision_shape := CylinderShape3D.new()
	collision_shape.radius = 0.45
	collision_shape.height = 3.2

	collision.shape = collision_shape
	collision.position.y = 1.6

	tree.add_child(collision)


func _spawn_rock(position: Vector3) -> void:
	var rock := StaticBody3D.new()
	rock.name = "Rock"

	generated_objects.add_child(rock)
	rock.global_position = position

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "RockMesh"

	var mesh := SphereMesh.new()
	mesh.radius = rng.randf_range(0.35, 0.8)
	mesh.height = rng.randf_range(0.35, 0.7)

	mesh_instance.mesh = mesh
	mesh_instance.scale = Vector3(
		rng.randf_range(1.0, 1.6),
		rng.randf_range(0.5, 0.9),
		rng.randf_range(1.0, 1.6)
	)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.35, 0.35)
	mesh_instance.material_override = material

	rock.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var collision_shape := SphereShape3D.new()
	collision_shape.radius = 0.7

	collision.shape = collision_shape

	rock.add_child(collision)
```

---

## 4. `res://scripts/resource_node.gd`

```gdscript
extends StaticBody3D

@export var resource_type: String = "wood"
@export var resource_amount: int = 1

var depleted: bool = false

func interact(player: Node) -> void:
	if depleted:
		return

	if resource_type == "wood":
		if player.has_method("add_wood"):
			player.add_wood(resource_amount)

	depleted = true
	queue_free()
```

This makes trees disappear when collected. That is crude, but correct for the first prototype.

Later, this can be replaced with:

```text
- tree health
- chopping animation
- falling tree physics
- stump remains
- log drops
```

Do not implement that yet.

---

## 5. `res://scripts/campfire.gd`

```gdscript
extends StaticBody3D

func _ready() -> void:
	_build_visual()
	_build_collision()


func _build_visual() -> void:
	var base := MeshInstance3D.new()
	base.name = "CampfireBase"

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.75
	base_mesh.bottom_radius = 0.75
	base_mesh.height = 0.15

	base.mesh = base_mesh
	base.position.y = 0.075

	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color(0.15, 0.12, 0.1)
	base.material_override = base_material

	add_child(base)

	for i in 4:
		var log := MeshInstance3D.new()
		log.name = "Log"

		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.08
		log_mesh.bottom_radius = 0.08
		log_mesh.height = 1.1

		log.mesh = log_mesh
		log.position.y = 0.25
		log.rotation.z = deg_to_rad(90)
		log.rotation.y = deg_to_rad(i * 45)

		var log_material := StandardMaterial3D.new()
		log_material.albedo_color = Color(0.35, 0.18, 0.08)
		log.material_override = log_material

		add_child(log)

	var flame := MeshInstance3D.new()
	flame.name = "PlaceholderFlame"

	var flame_mesh := ConeMesh.new()
	flame_mesh.bottom_radius = 0.25
	flame_mesh.top_radius = 0.0
	flame_mesh.height = 0.8

	flame.mesh = flame_mesh
	flame.position.y = 0.65

	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(1.0, 0.35, 0.05)
	flame.material_override = flame_material

	add_child(flame)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()

	shape.radius = 0.8
	shape.height = 0.4

	collision.shape = shape
	collision.position.y = 0.2

	add_child(collision)
```

---

## 6. `res://scripts/hud.gd`

```gdscript
extends CanvasLayer

@onready var wood_label: Label = $WoodLabel

func _ready() -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")

	if player == null:
		push_warning("HUD could not find Player node.")
		return

	if player.has_signal("wood_changed"):
		player.wood_changed.connect(_on_wood_changed)

	_on_wood_changed(player.wood_count)


func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Wood: %d" % new_amount
```

---

## 7. Input Map Setup

In Godot, go to:

```text
Project > Project Settings > Input Map
```

Add these actions:

```text
move_forward
move_backward
move_left
move_right
jump
interact
place_campfire
```

Suggested bindings:

```text
move_forward    W
move_backward   S
move_left       A
move_right      D
jump            Space
interact        E
place_campfire  B
```

`ui_cancel` already exists by default and is usually bound to `Esc`.

---

## 8. Player Setup

Your `Player` node should be a `CharacterBody3D`.

Add a collision shape:

```text
Player
├── CollisionShape3D
└── Camera3D
    └── InteractionRay
```

Use a `CapsuleShape3D` for `CollisionShape3D`.

Suggested values:

```text
Player position: (0, 1.1, 0)

CollisionShape3D:
  shape: CapsuleShape3D
  radius: 0.35
  height: 1.6
  position: (0, 0.8, 0)

Camera3D:
  position: (0, 1.6, 0)

InteractionRay:
  enabled: true
  target_position: (0, 0, -4)
```

---

## 9. Ground Setup

For `Ground`, use this:

```text
Ground: StaticBody3D
├── CollisionShape3D
└── MeshInstance3D
```

`CollisionShape3D`:

```text
shape: BoxShape3D
size: (100, 1, 100)
position: (0, -0.5, 0)
```

`MeshInstance3D`:

```text
mesh: BoxMesh
size: (100, 1, 100)
position: (0, -0.5, 0)
```

Give the ground a simple green material if desired.

---

## 10. Important Scene Tree Correction

The earlier tree had `InteractionRay` directly under `Player`, but this code expects it under the camera:

```text
Player
├── CollisionShape3D
└── Camera3D
    └── InteractionRay
```

This is better because the ray follows where the player is looking.

---

## 11. What This Prototype Proves

Once this runs, you have the minimum version of the game loop:

```text
spawn → explore forest → find trees → collect wood → place campfire
```

That is the correct first foundation.

After this, the next technical step should be one of these:

```text
1. Add terrain height/noise
2. Add a simple inventory
3. Add ghost-preview campfire placement
4. Add save/load
5. Add basic multiplayer
```

For this project, the next recommended step is **ghost-preview placement**, because it will make building feel better before complicating the simulation.
