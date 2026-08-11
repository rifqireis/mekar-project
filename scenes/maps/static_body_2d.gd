extends StaticBody2D

func interact(initiator: CharacterBody2D = null) -> void:
	var main_scene = get_tree().current_scene
	
	if main_scene.has_method("trigger_standalone_dialogue"):
		if not main_scene.is_list_taken:
			main_scene.trigger_standalone_dialogue("morning_interact")
			main_scene.is_list_taken = true
		else:
			main_scene.trigger_standalone_dialogue("morning_idle")
