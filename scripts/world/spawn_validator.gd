# spawn_validator.gd
extends RefCounted
## Checks basic terrain suitability for procedural world objects.

# TODO:
# - Check slope
# - Check distance from spawn
# - Check terrain height
# - Check whether a position is valid for trees, rocks, bushes, etc.
# - no trees too close to spawn
# - no rocks inside trees
# - no objects in water
# - no objects on steep slopes
# - no campfires intersecting existing objects
# - biome-specific spawn rules


# Rejects points near spawn or where local height differences exceed the limit.
static func is_suitable(
	terrain: BonfireTerrain,
	position: Vector3,
	min_spawn_distance: float = 6.0,
	check_distance: float = 1.5,
	max_height_difference: float = 0.9
) -> bool:
	if Vector2(position.x, position.z).length() < min_spawn_distance:
		return false

	var center: float = terrain.get_height_at(position.x, position.z)
	var nearby_x: float = terrain.get_height_at(position.x + check_distance, position.z)
	var nearby_z: float = terrain.get_height_at(position.x, position.z + check_distance)

	return (
		absf(center - nearby_x) <= max_height_difference
		and absf(center - nearby_z) <= max_height_difference
	)
