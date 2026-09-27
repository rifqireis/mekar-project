extends Control


func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("skip_scene"):
		SceneTransition.change_scene("res://game/world/bukit_kaba/bukit_kaba.tscn")

func change_scene() -> void:
	SceneTransition.change_scene("res://game/world/bukit_kaba/bukit_kaba.tscn")
