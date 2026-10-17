extends StaticBody3D

@export var resource_type: String = "wood"
@export var resource_amount: int = 1

var depleted: bool = false

func interact(player: Node) -> void:
	if depleted:
		return

	if resource_type == "wood":
		if player.has_method("add_wood"):
			player.add_wood(resource_amount)

	depleted = true
	queue_free()
	
