extends Control


func _ready() -> void:
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://gameplay/mandala/mandala_builder.tscn")


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://gameplay/mandala/mandala_builder.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/settingsmenu.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
