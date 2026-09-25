extends StaticBody2D

@export_category("Encounter Configuration")
@export var enemy_resource: Resource
@export var is_cutscene_active: bool = true 

var player_node: CharacterBody2D = null

func _ready() -> void:
	assert(enemy_resource != null, "ERROR: Missing EnemyData Resource in Inspector!")

func interact(initiator: CharacterBody2D = null) -> void:
	if initiator:
		player_node = initiator
		
	set_deferred("monitoring", false)
	
	if is_cutscene_active:
		player_node.set_physics_process(false)
		var main_scene: Node = get_tree().current_scene
		
		if main_scene.has_node("AnimationPlayer"):
			var anim_player: AnimationPlayer = main_scene.get_node("AnimationPlayer")
			
			anim_player.play("fade_in")
			anim_player.advance(0.1)
			anim_player.queue("rafflesia_encounter")
	
	else:
		execute_battle()

func execute_battle() -> void:
	if not player_node:
		print("ERROR BATTLE: player_node is null! Transition aborted.")
		return
		
	var current_map_path: String = get_tree().current_scene.scene_file_path
	
	PlayerRepository.start_battle(enemy_resource, player_node.global_position, current_map_path)
