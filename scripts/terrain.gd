class_name BonfireTerrain
extends StaticBody3D
## Generates a noise-based terrain mesh and corresponding heightmap collision.

const MaterialFactory = preload("res://scripts/factories/material_factory.gd")

@export_range(16, 256, 1) var grid_resolution: int = 96
@export_range(0.25, 4.0, 0.25) var cell_size: float = 1.0
@export var height_scale: float = 4.0
@export var noise_frequency: float = 0.045
@export var seed_value: int = 12345

@export var spawn_flatten_radius: float = 8.0
@export var spawn_blend_radius: float = 18.0

var noise := FastNoiseLite.new()
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D


# Creates terrain children, sets up noise, and builds mesh plus collision.
func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	add_to_group("terrain")
	_setup_child_nodes()
	_setup_noise()
	generate_terrain()


# Replaces legacy box-ground children with the generated terrain components.
func _setup_child_nodes() -> void:
	for child in get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			remove_child(child)
			child.free()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GeneratedTerrainMesh"
	add_child(mesh_instance)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "GeneratedTerrainCollision"
	add_child(collision_shape)

	mesh_instance.transform = Transform3D.IDENTITY
	collision_shape.transform = Transform3D.IDENTITY
	collision_shape.disabled = false


# Configures deterministic fractal noise for rolling hills.
func _setup_noise() -> void:
	noise.seed = seed_value
	noise.frequency = noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0


# Builds the visible triangle grid and its heightmap physics shape.
func generate_terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var heights := PackedFloat32Array()

	var count := grid_resolution + 1
	var half_size := float(grid_resolution) * cell_size * 0.5
	heights.resize(count * count)

	for z in range(count):
		for x in range(count):
			var px := float(x) * cell_size - half_size
			var pz := float(z) * cell_size - half_size
			var py := _sample_local_height(px, pz)
			var index := z * count + x

			heights[index] = py
			vertices.append(Vector3(px, py, pz))
			normals.append(Vector3.ZERO)
			uvs.append(Vector2(float(x) / grid_resolution, float(z) / grid_resolution))

	for z in range(grid_resolution):
		for x in range(grid_resolution):
			var i0 := z * count + x
			var i1 := i0 + 1
			var i2 := i0 + count
			var i3 := i2 + 1

			# Winding order faces upward instead of making the terrain invisible.
			indices.append_array(PackedInt32Array([i0, i2, i1, i1, i2, i3]))

	_calculate_normals(vertices, normals, indices)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = terrain_mesh
	mesh_instance.material_override = MaterialFactory.terrain_grass()

	_build_heightmap_collision(count, heights)


# Assigns collision heights in the same grid order as the visible mesh.
func _build_heightmap_collision(count: int, heights: PackedFloat32Array) -> void:
	var shape := HeightMapShape3D.new()
	shape.map_width = count
	shape.map_depth = count
	shape.map_data = heights
	collision_shape.shape = shape
	collision_shape.scale = Vector3(cell_size, 1.0, cell_size)
	collision_shape.disabled = false


# Averages adjacent triangle normals to produce smooth lighting.
func _calculate_normals(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array
) -> void:
	for start in range(0, indices.size(), 3):
		var a := indices[start]
		var b := indices[start + 1]
		var c := indices[start + 2]
		var normal := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).normalized()
		normals[a] += normal
		normals[b] += normal
		normals[c] += normal

	for i in range(normals.size()):
		normals[i] = normals[i].normalized()


# Samples noise and flattens the central spawn area with a smooth transition.
func _sample_local_height(local_x: float, local_z: float) -> float:
	var raw_height := noise.get_noise_2d(local_x, local_z) * height_scale
	var distance := Vector2(local_x, local_z).length()

	if distance <= spawn_flatten_radius:
		return 0.0

	if distance < spawn_blend_radius:
		var blend := inverse_lerp(spawn_flatten_radius, spawn_blend_radius, distance)
		return lerp(0.0, raw_height, smoothstep(0.0, 1.0, blend))

	return raw_height


# Returns the noise terrain height at a world-space X/Z coordinate.
func get_height_at(world_x: float, world_z: float) -> float:
	var local_point := to_local(Vector3(world_x, global_position.y, world_z))
	return global_position.y + _sample_local_height(local_point.x, local_point.z)
