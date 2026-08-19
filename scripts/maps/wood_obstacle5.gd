extends StaticBody2D

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "wood_obstacle"

@export_file("*.tscn") var target_scene_path: String = ""


func interact(player: CharacterBody2D) -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	
	player.set_physics_process(false)
	if "is_in_cutscene" in player:
		player.is_in_cutscene = true
	if player.has_method("play_cutscene_animation"):
		player.play_cutscene_animation("idle_down")
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
		await DialogueManager.dialogue_ended
	
	if tween.is_running():
		await tween.finished
		
	await get_tree().create_timer(0.2).timeout
	
	if not target_scene_path.is_empty():
		PlayerRepository.should_restore_position = false
		SceneTransition.change_scene(target_scene_path)
	else:
		player.set_physics_process(true)
		if "is_in_cutscene" in player:
			player.is_in_cutscene = false
		if player.has_method("stop_cutscene_animation"):
			player.stop_cutscene_animation()
			
		queue_free()
