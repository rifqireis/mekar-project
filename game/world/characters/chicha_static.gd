extends StaticBody2D

@export var dialogue_resource: DialogueResource

func interact(initiator: CharacterBody2D = null) -> void:
	var main_scene = get_tree().current_scene
	
	if initiator and initiator.has_method("set_physics_process"):
		initiator.set_physics_process(false)
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, "interact_chika", [main_scene])
	await DialogueManager.dialogue_ended
	
	if initiator and initiator.has_method("set_physics_process"):
		initiator.set_physics_process(true)
