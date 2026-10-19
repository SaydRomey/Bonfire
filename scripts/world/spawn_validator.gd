extends RefCounted
## Applies basic terrain suitability rules to world-object spawning.


# Returns true when a point is away from spawn and the nearby terrain is gentle.
static func is_suitable(
	terrain: BonfireTerrain,
	position: Vector3,
	min_spawn_distance: float = 6.0,
	check_distance: float = 1.5,
	max_height_difference: float = 0.9
) -> bool:
	if Vector2(position.x, position.z).length() < min_spawn_distance:
		return false

	var center := terrain.get_height_at(position.x, position.z)
	var nearby_x := terrain.get_height_at(position.x + check_distance, position.z)
	var nearby_z := terrain.get_height_at(position.x, position.z + check_distance)

	return (
		abs(center - nearby_x) <= max_height_difference
		and abs(center - nearby_z) <= max_height_difference
	)
