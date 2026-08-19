extends CharacterBody2D

@export var dialogue_resource: DialogueResource

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var map_owner: Node2D = get_owner()

var is_interacting: bool = false

func _ready() -> void:
	pass

func interact(_interactor: Node = null) -> void:
	if is_interacting:
		return
		
	is_interacting = true
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, "interact_orey", [map_owner])
	await DialogueManager.dialogue_ended
	
	is_interacting = false
