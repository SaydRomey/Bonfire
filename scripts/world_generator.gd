# world_generator.gd
extends Node

const TreeFactory := preload("res://scripts/factories/tree_factory.gd")
const RockFactory := preload("res://scripts/factories/rock_factory.gd")

@export var world_size: float = 80.0
@export var tree_count: int = 120
@export var rock_count: int = 45
@export var seed_value: int = 12345

@onready var generated_objects: Node3D = $"../GeneratedObjects"
@onready var terrain: Node = $"../Ground"

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = seed_value
	call_deferred("generate_world")


func generate_world() -> void:
	_clear_generated_objects()

	for i in range(tree_count):
		var position := _random_valid_world_position()
		_spawn_tree(position)

	for i in range(rock_count):
		var position := _random_valid_world_position()
		_spawn_rock(position)


func _clear_generated_objects() -> void:
	for child in generated_objects.get_children():
		child.queue_free()


func _random_valid_world_position() -> Vector3:
	for attempt in range(30):
		var position := _random_world_position()

		if _is_reasonably_flat(position):
			return position

	return _random_world_position()


func _random_world_position() -> Vector3:
	var half_size := world_size * 0.5

	var x := rng.randf_range(-half_size, half_size)
	var z := rng.randf_range(-half_size, half_size)
	var y := 0.0

	if terrain != null and terrain.has_method("get_height_at"):
		y = terrain.get_height_at(x, z)

	return Vector3(x, y, z)


func _is_reasonably_flat(position: Vector3) -> bool:
	if terrain == null or not terrain.has_method("get_height_at"):
		return true

	var check_distance := 1.5
	var max_height_difference := 0.9

	var center_height: float = terrain.get_height_at(position.x, position.z)
	var x_height: float = terrain.get_height_at(position.x + check_distance, position.z)
	var z_height: float = terrain.get_height_at(position.x, position.z + check_distance)

	if abs(center_height - x_height) > max_height_difference:
		return false

	if abs(center_height - z_height) > max_height_difference:
		return false

	return true


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
	mesh_instance.position.y = 0.25
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
	collision.position.y = 0.25

	rock.add_child(collision)
