# tree_factory.gd
extends RefCounted


static func create_tree(resource_amount: int = 1) -> StaticBody3D:
	var tree := StaticBody3D.new()
	tree.name = "Tree"

	tree.set_script(preload("res://scripts/resource_node.gd"))
	tree.resource_type = "wood"
	tree.resource_amount = resource_amount

	_add_trunk(tree)
	_add_leaves(tree)
	_add_collision(tree)

	return tree


static func _add_trunk(tree: StaticBody3D) -> void:
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


static func _add_leaves(tree: StaticBody3D) -> void:
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


static func _add_collision(tree: StaticBody3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var collision_shape := CylinderShape3D.new()
	collision_shape.radius = 0.45
	collision_shape.height = 3.2

	collision.shape = collision_shape
	collision.position.y = 1.6

	tree.add_child(collision)
