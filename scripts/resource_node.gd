# ressource_node.gd
class_name BonfireResourceNode
extends StaticBody3D
## Resource-bearing world object that responds to the player's interaction ray.

@export var resource_type: String = "wood"
@export var resource_amount: int = 1

var depleted: bool = false


# Gives the player this resource once, then removes the world object.
func interact(player: Node) -> void:
	if depleted or not player.has_method("add_wood"):
		return

	if resource_type != "wood":
		return  # Other resource types will be handled by the future inventory system.

	depleted = true
	player.call("add_wood", resource_amount)
	queue_free()
