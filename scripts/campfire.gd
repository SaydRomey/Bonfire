# campfire.gd
extends StaticBody3D

@export var is_preview: bool = false

var _preview_valid: bool = true
var _visual_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_build_visual()

	if not is_preview:
		_build_collision()
	else:
		set_preview_valid(true)


func set_preview_valid(valid: bool) -> void:
	_preview_valid = valid

	if not is_preview:
		return

	var preview_color: Color

	if valid:
		preview_color = Color(0.2, 1.0, 0.2, 0.45)
	else:
		preview_color = Color(1.0, 0.1, 0.1, 0.45)

	for material in _visual_materials:
		material.albedo_color = preview_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color

	if is_preview:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.45
		_visual_materials.append(material)

	return material


func _build_visual() -> void:
	var base := MeshInstance3D.new()
	base.name = "CampfireBase"

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.75
	base_mesh.bottom_radius = 0.75
	base_mesh.height = 0.15

	base.mesh = base_mesh
	base.position.y = 0.075
	base.material_override = _make_material(Color(0.15, 0.12, 0.1))

	add_child(base)

	for i in 4:
		var wood_log := MeshInstance3D.new()
		wood_log.name = "Log"

		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.08
		log_mesh.bottom_radius = 0.08
		log_mesh.height = 1.1

		wood_log.mesh = log_mesh
		wood_log.position.y = 0.25
		wood_log.rotation.z = deg_to_rad(90)
		wood_log.rotation.y = deg_to_rad(i * 45)
		wood_log.material_override = _make_material(Color(0.35, 0.18, 0.08))

		add_child(wood_log)

	var flame := MeshInstance3D.new()
	flame.name = "PlaceholderFlame"

	var flame_mesh := CylinderMesh.new()
	flame_mesh.bottom_radius = 0.25
	flame_mesh.top_radius = 0.0
	flame_mesh.height = 0.8

	flame.mesh = flame_mesh
	flame.position.y = 0.65
	flame.material_override = _make_material(Color(1.0, 0.35, 0.05))

	add_child(flame)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()

	shape.radius = 0.8
	shape.height = 0.4

	collision.shape = shape
	collision.position.y = 0.2

	add_child(collision)
