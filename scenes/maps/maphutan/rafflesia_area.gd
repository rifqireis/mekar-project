extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_deferred("monitoring", false)
		
		var main_scene: Node = get_tree().current_scene
		if main_scene.has_method("trigger_standalone_dialogue"):
			main_scene.trigger_standalone_dialogue("pre_rafflesia", "idle_up")
