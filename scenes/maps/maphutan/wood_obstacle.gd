extends StaticBody2D

func interact(_player: CharacterBody2D) -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	
	_player.set_physics_process(false)
	
	var main_scene: Node = get_tree().current_scene
	if main_scene.has_node("AnimationPlayer"):
		main_scene.get_node("AnimationPlayer").play("remove_wood_sequence")
