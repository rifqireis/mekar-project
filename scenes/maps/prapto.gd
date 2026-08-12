extends Node2D

@export var dialogue_resource: DialogueResource
@export_file("*.tscn") var next_map_path: String = "res://scenes/maps/maphutan_bab2(3).tscn"

@onready var player: CharacterBody2D = $Player

var is_list_taken: bool = true
var is_groceries_bought: bool = false
var is_cutscene_running: bool = false

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
	get_tree().change_scene_to_file(next_map_path)
