# hud.gd
extends CanvasLayer
## Displays resource counts and manages pause/inventory screens.

# TODO: For multiplayer, menus should block only the local player's input.

enum Screen { GAME,	PAUSE, INVENTORY }

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


# Connects menu buttons and resource updates, then opens gameplay.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Menus still work when the tree is paused.

	resume_button.pressed.connect(_resume_game)
	main_menu_button.pressed.connect(_return_to_main_menu)
	quit_button.pressed.connect(_quit_game)

	if player.has_signal("wood_changed"):
		player.connect("wood_changed", _on_wood_changed)

	_on_wood_changed(int(player.get("wood_count")))

	help_label.text = \
        "WASD Move | E Collect/Place | B Campfire | I Inventory | Esc Pause"

	_set_screen(Screen.GAME)


# Toggles the pause or inventory screen before gameplay receives the event.
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


# Updates visible menus, the world pause state, and mouse capture together.
func _set_screen(screen: Screen) -> void:
	current_screen = screen
	var is_gameplay: bool = screen == Screen.GAME
		
	wood_label.visible = is_gameplay
	help_label.visible = is_gameplay

	pause_menu.visible = screen == Screen.PAUSE
	inventory_menu.visible = screen == Screen.INVENTORY

	get_tree().paused = not is_gameplay

	if is_gameplay:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Shows the current wood count in the HUD and inventory screen.
func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Wood: %d" % new_amount
	inventory_wood_count.text = "Wood: %d" % new_amount


# Returns to first-person gameplay.
func _resume_game() -> void:
	_set_screen(Screen.GAME)


# Unpauses and opens the main menu scene.
func _return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Closes the running application.
func _quit_game() -> void:
	get_tree().quit()
