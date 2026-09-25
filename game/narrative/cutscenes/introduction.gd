extends Control


func _ready() -> void:
	pass


func change_scene() -> void:
	SceneTransition.change_scene("res://game/world/bukit_kaba/bukit_kaba.tscn")
