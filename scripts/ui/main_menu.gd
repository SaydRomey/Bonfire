# main_menu.gd
extends Control

@onready var play_button: TextureButton = \
	$CenterContainer/MenuPanel/MarginContainer/Buttons/PlayButton

@onready var settings_button: TextureButton = \
	$CenterContainer/MenuPanel/MarginContainer/Buttons/SettingsButton

@onready var quit_button: TextureButton = \
	$CenterContainer/MenuPanel/MarginContainer/Buttons/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://scenes/main.tscn"
	)


func _on_settings_pressed() -> void:
	# TODO
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
