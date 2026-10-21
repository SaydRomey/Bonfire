# hud.gd
extends CanvasLayer
## Manages the game HUD, pause menu, and inventory.

#TODO: Eventually, in multiplayer, we'll replace this with
# local player input locking so that one person's inventory 
# or pause menu doesn't stop the shared world.

enum Screen {
	GAME,
	PAUSE,
	INVENTORY
}

var current_screen: Screen = Screen.GAME

@onready var player: CharacterBody3D = $"../Player"

@onready var wood_label: Label = $WoodLabel
@onready var help_label: Label = $HelpLabel

@onready var pause_menu: Control = $PauseMenu
@onready var inventory_menu: Control = $InventoryMenu

@onready var inventory_wood_count: Label = \
	$InventoryMenu/CenterContainer/Panel/MarginContainer/Content/WoodCount

@onready var resume_button: TextureButton = \
	$PauseMenu/CenterContainer/Panel/MarginContainer/Buttons/ResumeButton

@onready var main_menu_button: TextureButton = \
	$PauseMenu/CenterContainer/Panel/MarginContainer/Buttons/MainMenuButton

@onready var quit_button: TextureButton = \
	$PauseMenu/CenterContainer/Panel/MarginContainer/Buttons/QuitButton


func _ready() -> void:
	# The HUD must receive input while the world is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(_resume_game)
	main_menu_button.pressed.connect(_return_to_main_menu)
	quit_button.pressed.connect(_quit_game)

	if player.has_signal("wood_changed"):
		player.connect("wood_changed", _on_wood_changed)

	_on_wood_changed(int(player.get("wood_count")))

	help_label.text = \
        "WASD Move | E Collect/Place | B Campfire | I Inventory | Esc Pause"

	_set_screen(Screen.GAME)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_screen == Screen.GAME:
			_set_screen(Screen.PAUSE)
		else:
			_set_screen(Screen.GAME)

		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_inventory"):
		if current_screen == Screen.PAUSE:
			return

		if current_screen == Screen.INVENTORY:
			_set_screen(Screen.GAME)
		else:
			_set_screen(Screen.INVENTORY)

		get_viewport().set_input_as_handled()


func _set_screen(screen: Screen) -> void:
	current_screen = screen
	
	wood_label.visible = screen == Screen.GAME
	help_label.visible = screen == Screen.GAME

	pause_menu.visible = screen == Screen.PAUSE
	inventory_menu.visible = screen == Screen.INVENTORY

	var is_gameplay: bool = screen == Screen.GAME

	get_tree().paused = not is_gameplay

	if is_gameplay:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Wood: %d" % new_amount
	inventory_wood_count.text = "Wood: %d" % new_amount


func _resume_game() -> void:
	_set_screen(Screen.GAME)


func _return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().change_scene_to_file(
        "res://scenes/main_menu.tscn"
	)


func _quit_game() -> void:
	get_tree().quit()


## Connects the HUD to the player and displays the initial resource count.
#func _ready() -> void:
	#var player := get_tree().current_scene.get_node_or_null("Player")
	#if player == null:
		#push_warning("HUD could not find Main/Player.")
		#return
#
	#if player.has_signal("wood_changed"):
		#player.connect("wood_changed", _on_wood_changed)
	#_on_wood_changed(int(player.get("wood_count")))
#
#
## Updates the counter when wood is collected or spent.
#func _on_wood_changed(new_amount: int) -> void:
	#wood_label.text = "Wood: %d" % new_amount
