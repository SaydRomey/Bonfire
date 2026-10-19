extends RefCounted
## Centralizes simple prototype materials.


# Creates an opaque, rough material using the provided color.
static func make_standard(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


# Creates a transparent material with the specified opacity.
static func make_transparent(color: Color, alpha: float = 0.45) -> StandardMaterial3D:
	var material := make_standard(Color(color.r, color.g, color.b, alpha))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


# Returns the material used by tree trunks and wooden logs.
static func bark() -> StandardMaterial3D:
	return make_standard(Color(0.35, 0.18, 0.08))


# Returns the material used by tree foliage.
static func leaves() -> StandardMaterial3D:
	return make_standard(Color(0.08, 0.35, 0.12))


# Returns the material used by rocks.
static func rock() -> StandardMaterial3D:
	return make_standard(Color(0.35, 0.35, 0.35))


# Returns a bright grass material with two-sided rendering for terrain debugging.
static func terrain_grass() -> StandardMaterial3D:
	var material := make_standard(Color(0.18, 0.55, 0.16))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
