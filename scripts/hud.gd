extends CanvasLayer

@onready var wood_label: Label = $WoodLabel

func _ready() -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")

	if player == null:
		push_warning("HUD could not find Player node.")
		return

	if player.has_signal("wood_changed"):
		player.wood_changed.connect(_on_wood_changed)

	_on_wood_changed(player.wood_count)


func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Wood: %d" % new_amount
	
