# rock_factory.gd
extends RefCounted


static func create_rock(rng: RandomNumberGenerator) -> StaticBody3D:
	var rock := StaticBody3D.new()
	rock.name = "Rock"

	_add_visual(rock, rng)
	_add_collision(rock)

	return rock


static func _add_visual(rock: StaticBody3D, rng: RandomNumberGenerator) -> void:
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


static func _add_collision(rock: StaticBody3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var collision_shape := SphereShape3D.new()
	collision_shape.radius = 0.7

	collision.shape = collision_shape
	collision.position.y = 0.25

	rock.add_child(collision)
