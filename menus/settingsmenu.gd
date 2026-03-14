extends Control


func _ready() -> void:
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/mainmenu.tscn")
