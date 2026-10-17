# terrain.gd
extends StaticBody3D

@export var grid_resolution: int = 96
@export var cell_size: float = 1.0
@export var height_scale: float = 4.0
@export var noise_frequency: float = 0.045
@export var seed_value: int = 12345

@export var spawn_flatten_radius: float = 8.0
@export var spawn_blend_radius: float = 18.0

var noise := FastNoiseLite.new()

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var height_data := PackedFloat32Array()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1

	_setup_child_nodes()
	_setup_noise()
	generate_terrain()


#func _setup_child_nodes() -> void:
	#mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	#collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
#
	#if mesh_instance == null:
		#mesh_instance = MeshInstance3D.new()
		#mesh_instance.name = "MeshInstance3D"
		#add_child(mesh_instance)
#
	#if collision_shape == null:
		#collision_shape = CollisionShape3D.new()
		#collision_shape.name = "CollisionShape3D"
		#add_child(collision_shape)
#
	## Important: old transforms from the previous box-ground setup can break alignment.
	#mesh_instance.position = Vector3.ZERO
	#mesh_instance.rotation = Vector3.ZERO
	#mesh_instance.scale = Vector3.ONE
#
	#collision_shape.position = Vector3.ZERO
	#collision_shape.rotation = Vector3.ZERO
	#collision_shape.scale = Vector3(cell_size, 1.0, cell_size)
	#collision_shape.disabled = false


func _setup_child_nodes() -> void:
	# Hard-delete old children from previous terrain/box-ground versions.
	for child in get_children():
		remove_child(child)
		child.free()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GeneratedTerrainMesh"
	add_child(mesh_instance)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "GeneratedTerrainCollision"
	add_child(collision_shape)

	mesh_instance.position = Vector3.ZERO
	mesh_instance.rotation = Vector3.ZERO
	mesh_instance.scale = Vector3.ONE
	mesh_instance.visible = true

	collision_shape.position = Vector3.ZERO
	collision_shape.rotation = Vector3.ZERO
	collision_shape.scale = Vector3(cell_size, 1.0, cell_size)
	collision_shape.disabled = false


func _setup_noise() -> void:
	noise.seed = seed_value
	noise.frequency = noise_frequency
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0


func generate_terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var vertex_count_per_side := grid_resolution + 1
	var half_size := float(grid_resolution) * cell_size * 0.5

	height_data = PackedFloat32Array()
	height_data.resize(vertex_count_per_side * vertex_count_per_side)

	for z in range(vertex_count_per_side):
		for x in range(vertex_count_per_side):
			var local_x := float(x) * cell_size - half_size
			var local_z := float(z) * cell_size - half_size
			var local_y := _sample_local_height(local_x, local_z)

			var index := z * vertex_count_per_side + x
			height_data[index] = local_y

			vertices.append(Vector3(local_x, local_y, local_z))
			normals.append(Vector3.ZERO)
			uvs.append(Vector2(
				float(x) / float(grid_resolution),
				float(z) / float(grid_resolution)
			))

	for z in range(grid_resolution):
		for x in range(grid_resolution):
			var i0 := z * vertex_count_per_side + x
			var i1 := i0 + 1
			var i2 := i0 + vertex_count_per_side
			var i3 := i2 + 1

			indices.append(i0)
			indices.append(i2)
			indices.append(i1)

			indices.append(i1)
			indices.append(i2)
			indices.append(i3)

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
	mesh_instance.material_override = _make_terrain_material()

	_build_heightmap_collision(vertex_count_per_side)

	print("Terrain generated.")
	print("Terrain mesh vertices: ", vertices.size())
	print("HeightMap collision points: ", height_data.size())
	print("Collision shape assigned: ", collision_shape.shape != null)


func _build_heightmap_collision(vertex_count_per_side: int) -> void:
	var shape := HeightMapShape3D.new()

	shape.map_width = vertex_count_per_side
	shape.map_depth = vertex_count_per_side
	shape.map_data = height_data

	collision_shape.shape = shape
	collision_shape.scale = Vector3(cell_size, 1.0, cell_size)
	collision_shape.disabled = false


func _calculate_normals(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array
) -> void:
	for triangle_start in range(0, indices.size(), 3):
		var index_a := indices[triangle_start]
		var index_b := indices[triangle_start + 1]
		var index_c := indices[triangle_start + 2]

		var a := vertices[index_a]
		var b := vertices[index_b]
		var c := vertices[index_c]

		var normal := (b - a).cross(c - a).normalized()

		normals[index_a] += normal
		normals[index_b] += normal
		normals[index_c] += normal

	for i in range(normals.size()):
		normals[i] = normals[i].normalized()


func _sample_local_height(local_x: float, local_z: float) -> float:
	var raw_height := noise.get_noise_2d(local_x, local_z) * height_scale

	var distance_from_spawn := Vector2(local_x, local_z).length()

	if distance_from_spawn <= spawn_flatten_radius:
		return 0.0

	if distance_from_spawn < spawn_blend_radius:
		var blend := inverse_lerp(spawn_flatten_radius, spawn_blend_radius, distance_from_spawn)
		blend = smoothstep(0.0, 1.0, blend)
		return lerp(0.0, raw_height, blend)

	return raw_height


func get_height_at(world_x: float, world_z: float) -> float:
	var local_position := to_local(Vector3(world_x, global_position.y, world_z))
	var local_height := _sample_local_height(local_position.x, local_position.z)

	return global_position.y + local_height


#func _make_terrain_material() -> StandardMaterial3D:
	#var material := StandardMaterial3D.new()
	#material.albedo_color = Color(0.16, 0.38, 0.13)
	#material.roughness = 1.0
	#return material

func _make_terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.55, 0.16)
	material.roughness = 1.0

	# Useful while debugging terrain visibility.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	return material
