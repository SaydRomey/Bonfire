extends Node
## Selects deterministic spawn positions and delegates object construction to factories.

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


# Clears and repopulates the forest with trees and rocks.
func generate_world() -> void:
	_clear_generated_objects()
	_generate_trees()
	_generate_rocks()


# Creates and positions collectible trees.
func _generate_trees() -> void:
	for i in range(tree_count):
		var tree := TreeFactory.create_tree(1)
		generated_objects.add_child(tree)
		tree.global_position = _random_valid_world_position()


# Creates and positions varied rocks.
func _generate_rocks() -> void:
	for i in range(rock_count):
		var rock := RockFactory.create_rock(rng)
		generated_objects.add_child(rock)
		rock.global_position = _random_valid_world_position()


# Removes previously generated objects before regeneration.
func _clear_generated_objects() -> void:
	for child in generated_objects.get_children():
		generated_objects.remove_child(child)
		child.queue_free()


# Returns a suitable position, with a fallback if no candidate passes.
func _random_valid_world_position() -> Vector3:
	for attempt in range(30):
		var position := _random_world_position()
		if SpawnValidator.is_suitable(terrain, position):
			return position

	return _random_world_position()  # Keep generation from stalling indefinitely.


# Samples an X/Z position inside both the generator region and terrain bounds.
func _random_world_position() -> Vector3:
	var terrain_size: float = float(terrain.grid_resolution) * terrain.cell_size
	var half_size: float = maxf(0.0, minf(world_size, terrain_size - 4.0)) * 0.5

	var x: float = rng.randf_range(-half_size, half_size)
	var z: float = rng.randf_range(-half_size, half_size)

	return Vector3(x, terrain.get_height_at(x, z), z)
