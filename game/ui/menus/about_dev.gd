extends Node2D


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		get_tree().change_scene_to_file("res://game/ui/menus/main_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game/ui/menus/main_menu.tscn")
