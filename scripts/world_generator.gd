extends Node
## Places procedural resources; factories build objects, and validators check locations.

const TreeFactory = preload("res://scripts/factories/tree_factory.gd")
const RockFactory = preload("res://scripts/factories/rock_factory.gd")
const SpawnValidator = preload("res://scripts/world/spawn_validator.gd")

@export var world_size: float = 80.0
@export var tree_count: int = 120
@export var rock_count: int = 45
@export var seed_value: int = 12345

@onready var generated_objects: Node3D = $"../GeneratedObjects"
@onready var terrain: BonfireTerrain = $"../Ground"

var rng := RandomNumberGenerator.new()


# Initializes the seeded generator after the terrain is available.
func _ready() -> void:
	rng.seed = seed_value
	call_deferred("generate_world")


# Rebuilds the same forest for the same seed and settings.
func generate_world() -> void:
	rng.seed = seed_value  # Reset the sequence for deterministic regeneration.
	_clear_generated_objects()
	_generate_trees()
	_generate_rocks()


# Places collectible trees at approved terrain positions.
func _generate_trees() -> void:
	for _index in range(tree_count):
		var location: Dictionary = _find_valid_spawn_position()
		if location.is_empty():
			continue

		var tree := TreeFactory.create_tree(1)
		generated_objects.add_child(tree)
		tree.global_position = location["position"]


# Places rocks at approved terrain positions.
func _generate_rocks() -> void:
	for _index in range(rock_count):
		var location: Dictionary = _find_valid_spawn_position()
		if location.is_empty():
			continue

		var rock := RockFactory.create_rock(rng)
		generated_objects.add_child(rock)
		rock.global_position = location["position"]


# Removes previous procedural objects before regeneration.
func _clear_generated_objects() -> void:
	for child in generated_objects.get_children():
		generated_objects.remove_child(child)
		child.queue_free()


# Finds a suitable point, or returns an empty result instead of using an invalid one.
func _find_valid_spawn_position() -> Dictionary:
	for _attempt in range(30):
		var position: Vector3 = _random_world_position()
		if SpawnValidator.is_suitable(terrain, position):
			return {"position": position}

	return {}  # Skip this object if no safe location was found.


# Samples a point inside the playable terrain, leaving a small edge margin.
func _random_world_position() -> Vector3:
	var terrain_size: float = float(terrain.grid_resolution) * terrain.cell_size
	var half_size: float = maxf(0.0, minf(world_size, terrain_size - 4.0)) * 0.5
	var x: float = rng.randf_range(-half_size, half_size)
	var z: float = rng.randf_range(-half_size, half_size)
	return Vector3(x, terrain.get_height_at(x, z), z)
