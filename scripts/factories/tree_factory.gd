extends RefCounted
## Constructs trees without choosing where they should spawn.

const MaterialFactory = preload("res://scripts/factories/material_factory.gd")


# Creates a tree with visuals, collision, and collectible wood.
static func create_tree(resource_amount: int = 1) -> BonfireResourceNode:
	var tree := BonfireResourceNode.new()
	tree.name = "Tree"
	tree.resource_type = "wood"
	tree.resource_amount = resource_amount

	_add_trunk(tree)
	_add_leaves(tree)
	_add_collision(tree)
	return tree


# Adds the tree's brown cylindrical trunk.
static func _add_trunk(tree: StaticBody3D) -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 3.0

	trunk.mesh = trunk_mesh
	trunk.position.y = 1.5
	trunk.material_override = MaterialFactory.bark()
	tree.add_child(trunk)


# Adds the canopy above the trunk.
static func _add_leaves(tree: StaticBody3D) -> void:
	var leaves := MeshInstance3D.new()
	leaves.name = "Leaves"

	var leaves_mesh := SphereMesh.new()
	leaves_mesh.radius = 1.2
	leaves_mesh.height = 1.8

	leaves.mesh = leaves_mesh
	leaves.position.y = 3.1
	leaves.material_override = MaterialFactory.leaves()
	tree.add_child(leaves)


# Adds collision so the player and interaction ray can hit the trunk.
static func _add_collision(tree: StaticBody3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var shape := CylinderShape3D.new()
	shape.radius = 0.45
	shape.height = 3.2

	collision.shape = shape
	collision.position.y = 1.6
	tree.add_child(collision)
