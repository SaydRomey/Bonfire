# campfire.gd
class_name BonfireCampfire
extends StaticBody3D
## Renders a campfire as either a solid object or a colored placement preview.

const MaterialFactory = preload("res://scripts/factories/material_factory.gd")

@export var is_preview: bool = false

var _visual_materials: Array[StandardMaterial3D] = []


# Builds the visuals and adds collision only for placed campfires.
func _ready() -> void:
	_build_visual()
	if is_preview:
		set_preview_valid(true)
	else:
		_build_collision()


# Colors the placement preview green or red to indicate validity.
func set_preview_valid(valid: bool) -> void:
	if not is_preview:
		return

	var color := Color(0.2, 1.0, 0.2, 0.45)
	if not valid:
		color = Color(1.0, 0.1, 0.1, 0.45)

	for material in _visual_materials:
		material.albedo_color = color


# Makes a distinct material so preview tint does not recolor other objects.
func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D
	if is_preview:
		material = MaterialFactory.make_transparent(color)
		_visual_materials.append(material)
	else:
		material = MaterialFactory.make_standard(color)
	return material


# Builds a simple base, four wooden logs, and a cone-shaped placeholder flame.
func _build_visual() -> void:
	var base := MeshInstance3D.new()
	base.name = "CampfireBase"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.75
	base_mesh.bottom_radius = 0.75
	base_mesh.height = 0.15
	base.mesh = base_mesh
	base.position.y = 0.075
	base.material_override = _make_material(Color(0.15, 0.12, 0.10))
	add_child(base)

	for i in range(4):
		var wood_log := MeshInstance3D.new()
		wood_log.name = "Log"
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.08
		log_mesh.bottom_radius = 0.08
		log_mesh.height = 1.1
		wood_log.mesh = log_mesh
		wood_log.position.y = 0.25
		wood_log.rotation.z = deg_to_rad(90.0)
		wood_log.rotation.y = deg_to_rad(float(i) * 45.0)
		wood_log.material_override = _make_material(Color(0.35, 0.18, 0.08))
		add_child(wood_log)

	var flame := MeshInstance3D.new()
	flame.name = "PlaceholderFlame"
	var flame_mesh := CylinderMesh.new()
	flame_mesh.bottom_radius = 0.25
	flame_mesh.top_radius = 0.0  # Godot 4 uses a tapered CylinderMesh for cones.
	flame_mesh.height = 0.8
	flame.mesh = flame_mesh
	flame.position.y = 0.65
	flame.material_override = _make_material(Color(1.0, 0.35, 0.05))
	add_child(flame)


# Adds a simple collider to solid, permanently placed campfires.
func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = 0.4
	collision.shape = shape
	collision.position.y = 0.2
	add_child(collision)
