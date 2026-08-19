extends Node2D

@export var dialogue_resource: DialogueResource

@onready var player: CharacterBody2D = $Player
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var observation_remote: RemoteTransform2D = $ObservationPath/PlayerFollow/RemoteTransform2D
@onready var player_cam: Camera2D = $Player/Camera2D
@onready var rafflesia_cam: Camera2D = $RafflesiaCam

func _ready() -> void:
	player.set_physics_process(false)

func trigger_dialogue(dialogue_key: String) -> void:
	anim_player.pause() 
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_key, [self])
	await DialogueManager.dialogue_ended
	
	if not anim_player.is_playing():
		anim_player.advance(0.1)
		anim_player.play()
func trigger_standalone_dialogue(dialogue_key: String, idle_anim: String = "") -> void:
	player.set_physics_process(false)
	
	if idle_anim != "":
		player.play_cutscene_animation(idle_anim)
		
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_key, [self])
	await DialogueManager.dialogue_ended
	
	if player.has_method("stop_cutscene_animation"):
		player.stop_cutscene_animation()
	elif "is_in_cutscene" in player:
		player.is_in_cutscene = false
		
	player.set_physics_process(true)
func release_player() -> void:
	player.set_physics_process(true)
	
	if "is_in_cutscene" in player:
		player.is_in_cutscene = false
		
	if player.has_method("stop_cutscene_animation"):
		player.stop_cutscene_animation()
		
	change_cam_player()
	
	var tutorial_ui = get_node_or_null("Player/TutorialUI")
	if is_instance_valid(tutorial_ui):
		tutorial_ui.show_tutorial()

#func change_cam_intro() -> void:
	#var intro_cam = get_node_or_null("IntroCamera")
	#if is_instance_valid(intro_cam):
		#intro_cam.make_current()

#func change_cam_player() -> void:
	#player_cam.make_current()
	
#func change_cam_rafflesia() -> void:
	#rafflesia_cam.make_current()

func change_cam_intro(duration: float = 1.2) -> void:
	var intro_cam = get_node_or_null("IntroCamera")
	if is_instance_valid(intro_cam):
		await transition_camera_to(intro_cam, duration)

func change_cam_player(duration: float = 1.2) -> void:
	if is_instance_valid(player_cam):
		await transition_camera_to(player_cam, duration)
	
func change_cam_rafflesia(duration: float = 1.2) -> void:
	if is_instance_valid(rafflesia_cam):
		await transition_camera_to(rafflesia_cam, duration)

func bind_observation_path() -> void:
	observation_remote.remote_path = observation_remote.get_path_to(player)

func unbind_observation_path() -> void:
	observation_remote.remote_path = ""

func trigger_startle_effect() -> void:
	unbind_observation_path()
	
	var active_cam: Camera2D = get_viewport().get_camera_2d()
	if not active_cam:
		player_cam.make_current()
		active_cam = player_cam
	
	# 2. Tween Getar (Shake) pada kamera yang aktif
	var cam_tween: Tween = create_tween()
	cam_tween.tween_property(active_cam, "offset", Vector2(8, 8), 0.04)
	cam_tween.tween_property(active_cam, "offset", Vector2(-8, -8), 0.04)
	cam_tween.tween_property(active_cam, "offset", Vector2(6, -6), 0.04)
	cam_tween.tween_property(active_cam, "offset", Vector2(-6, 6), 0.04)
	cam_tween.tween_property(active_cam, "offset", Vector2.ZERO, 0.04)
	
	var move_tween: Tween = create_tween()
	var step_back_pos: Vector2 = player.global_position + Vector2(0, 25)
	move_tween.tween_property(player, "global_position", step_back_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	player.play_cutscene_animation("idle_down")

func transition_camera_to(to_cam: Camera2D, duration: float = 1.2) -> void:
	if not to_cam:
		return
		
	var current_cam: Camera2D = get_viewport().get_camera_2d()
	
	if not current_cam or current_cam == to_cam:
		to_cam.make_current()
		return
	
	var temp_cam := Camera2D.new()
	add_child(temp_cam)
	temp_cam.global_position = current_cam.global_position
	temp_cam.zoom = current_cam.zoom
	temp_cam.make_current()
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(temp_cam, "global_position", to_cam.global_position, duration)
	tween.tween_property(temp_cam, "zoom", to_cam.zoom, duration)
	
	await tween.finished
	
	to_cam.make_current()
	temp_cam.queue_free()
