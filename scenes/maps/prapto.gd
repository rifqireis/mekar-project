extends Node2D

@export var dialogue_resource: DialogueResource
@export_file("*.tscn") var next_map_path: String = "res://scenes/maps/maphutan_bab2.tscn"

@onready var player: CharacterBody2D = $Player

var is_list_taken: bool = true
var is_groceries_bought: bool = false
var is_cutscene_running: bool = false

func _ready() -> void:
	if player.has_method("set_camera_zoom"):
		player.set_camera_zoom(6.0)
		
func start_phone_call_cutscene() -> void:
	if is_cutscene_running:
		return
		
	is_cutscene_running = true
	
	if player.has_method("stop_cutscene_animation"):
		player.stop_cutscene_animation()
	
	await get_tree().create_timer(5.0).timeout
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, "phone_call", [self])
	await DialogueManager.dialogue_ended
	
	PlayerRepository.should_restore_position = false
	SceneTransition.change_scene(next_map_path)
