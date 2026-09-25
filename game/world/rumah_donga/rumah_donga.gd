extends Node2D

@export var dialogue_resource: DialogueResource

@onready var player: CharacterBody2D = $Player
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var camera_controller: CameraController = $CameraController

var is_list_taken: bool = false

func _ready() -> void:
	player.set_physics_process(false)
	if player.has_method("set_camera_zoom"):
		player.set_camera_zoom(6.0)

	anim_player.speed_scale = 1.0
	anim_player.play("autoload_animation")

	await anim_player.animation_finished

	player.set_physics_process(true)
	if camera_controller:
		camera_controller.release_to_player(0.5)	

func trigger_dialogue(title: String) -> void:
	anim_player.speed_scale = 0.0
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, title, [self])
	await DialogueManager.dialogue_ended
	
	anim_player.speed_scale = 1.0
