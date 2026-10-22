# rock_factory.gd
extends RefCounted
## Constructs slightly varied rocks using the world generator's seeded RNG.

const MaterialFactory = preload("res://scripts/factories/material_factory.gd")


# Creates a rock with matching approximate visual and collision dimensions.
static func create_rock(rng: RandomNumberGenerator) -> StaticBody3D:
	var rock := StaticBody3D.new()
	rock.name = "Rock"

	var radius := rng.randf_range(0.35, 0.8)
	var height := rng.randf_range(0.35, 0.7)
	var width_scale := rng.randf_range(1.0, 1.6)
	var depth_scale := rng.randf_range(1.0, 1.6)
	var vertical_scale := rng.randf_range(0.5, 0.9)

	_add_visual(rock, radius, height, Vector3(width_scale, vertical_scale, depth_scale))
	_add_collision(rock, radius * max(width_scale, depth_scale), height * vertical_scale)
	return rock


# Adds a flattened, variably scaled sphere as the visible rock.
static func _add_visual(rock: StaticBody3D, radius: float, height: float, visual_scale: Vector3) -> void:
	var visual := MeshInstance3D.new()
	visual.name = "RockMesh"

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height

	visual.mesh = mesh
	visual.position.y = 0.25
	visual.scale = visual_scale
	visual.material_override = MaterialFactory.rock()
	rock.add_child(visual)


# Adds an approximate cylindrical collider without scaling a physics shape.
static func _add_collision(rock: StaticBody3D, radius: float, height: float) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = max(height, 0.05)

	collision.shape = shape
	collision.position.y = 0.25
	rock.add_child(collision)
