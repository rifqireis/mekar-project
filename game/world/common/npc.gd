class_name UniversalNPC
extends StaticBody2D

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "npc0_seller"

var is_interacting: bool = false

func interact(_interactor: Node = null) -> void:
	if is_interacting or dialogue_resource == null:
		return
		
	is_interacting = true
	var map_owner = get_owner()
	
	var was_bought_before: bool = map_owner.get("is_groceries_bought") if "is_groceries_bought" in map_owner else false
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title, [map_owner, self])
	await DialogueManager.dialogue_ended
	
	is_interacting = false
	
	if "is_groceries_bought" in map_owner:
		if not was_bought_before and map_owner.is_groceries_bought:
			if map_owner.has_method("start_phone_call_cutscene"):
				map_owner.start_phone_call_cutscene()
