extends Area2D


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass

func interact(_initiator: CharacterBody2D = null) -> void:
	SceneTransition.change_scene("res://game/world/suprapto/suprapto.tscn")
