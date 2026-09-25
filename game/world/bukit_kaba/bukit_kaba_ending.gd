extends Node2D

@export var dialogue_resource: DialogueResource

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $Player
@onready var ghearld: CharacterBody2D = $"G'Hearld"  
@onready var video_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer

func _ready() -> void:
	if player.has_method("set_camera_zoom"):
		player.set_camera_zoom(6.0)
	if video_player:
		video_player.visible = false
	
	start_cutscene_sequence()

func start_cutscene_sequence() -> void:
	# 1. Mulai animasi jalan
	if anim_player and anim_player.has_animation("donga_walk"):
		anim_player.play("donga_walk")
	
	# 2. Eksekusi Dialog Monolog dengan Validasi Balon
	if dialogue_resource:
		var balloon_node = DialogueManager.show_dialogue_balloon(dialogue_resource, "monologue", [self])
		
		# Jika balon dialog berhasil dibuat, tunggu sampai selesai
		if is_instance_valid(balloon_node):
			await DialogueManager.dialogue_ended
		else:
			# JIKA BALON GAGAL MUNCUL DI EXPORT: Beri jeda 2 detik lalu paksa lanjut
			push_warning("Dialogue balloon gagal spawn, melanjutkan cutscene otomatis.")
			await get_tree().create_timer(2.0).timeout
	else:
		await get_tree().create_timer(2.0).timeout
	
	# 3. Animasi G'Hearld
	if anim_player and anim_player.has_animation("G'Hearld"):
		anim_player.play("G'Hearld")
		await anim_player.animation_finished
	
	# 4. Lanjut ke Video & Main Menu
	await play_cutscene_video()		
			
func play_cutscene_video() -> void:
	if video_player:
		video_player.visible = true
		video_player.play()
		
		await video_player.finished
		# get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
		anim_player.play("end")
		await anim_player.animation_finished
				
		SceneTransition.change_scene("res://game/ui/menus/main_menu.tscn")
