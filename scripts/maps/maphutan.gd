extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var dialogue_ui: TextureRect = $UIDialogueLayer/SlantedDialogueBox
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var observation_remote: RemoteTransform2D = $ObservationPath/PlayerFollow/RemoteTransform2D
@onready var player_cam: Camera2D = $Player/Camera2D
@onready var rafflesia_cam: Camera2D = $RafflesiaCam

var cam_tween: Tween

var dialogue_data: Dictionary = {
	"landing": [
		{"nama": "Donga", "teks": "Suspect 18. Mutasi Raflesia."},
		{"nama": "Donga", "teks": "Kalau lancar, aku besok udah bisa pulang ke-rumah. Orey pasti nanya lagi soal luka di lenganku yang kemarin."},
		{"nama": "Donga", "teks": "Aduduh, Fokus dulu. Nanti aja bayanginnya."}
	],
	"wood_obstacle": [
		{"nama": "Donga", "teks": "Kayu ini menghalangi jalan. Aku harus menyingkirkannya."},
		{"nama": "Donga", "teks": "Ugh... lumayan berat juga."}
	],
	"pre_rafflesia": [
		{"nama": "Donga", "teks": "Itu dia. Suspect 18."},
		{"nama": "Donga", "teks": "Ukurannya jauh lebih masif dari laporan awal. Aku harus memeriksanya lebih dekat."}
	],
	"investigation": [
		{"nama": "Donga", "teks": "Bukan sisa perkelahian. Ini ditandain."},
		{"nama": "Donga", "teks": "Dan lebih besar dari yang tertulis di laporan."}
	],
	"confrontation": [
		{"nama": "Donga", "teks": "Target teridentifikasi."},
		{"nama": "Arnoldios", "teks": "Kalian cabut akarku dari tanah ini. Kalian bakar rumahku buat batu dan besi. Sekarang kalian masih berdiri di sisa-sisanya."}
	],
	"pre_battle": [
		{"nama": "Donga", "teks": "K...KAU BISA BICARA!!"},
		{"nama": "Arnoldios", "teks": "MANUSIA, AKAN KUBINASAKAN KALIAN!!."}
	]
}

func _ready() -> void:
	anim_player.play("autoload_animation")
	player.set_physics_process(false)
	dialogue_ui.speaker_changed.connect(_on_speaker_changed)

func trigger_dialogue(dialogue_key: String) -> void:
	anim_player.pause() 
	dialogue_ui.start_dialogue(dialogue_data[dialogue_key])
		
func trigger_standalone_dialogue(dialogue_key: String, idle_anim: String = "") -> void:
	player.set_physics_process(false)
	
	if idle_anim != "":
		player.play_cutscene_animation(idle_anim)
		
	dialogue_ui.start_dialogue(dialogue_data[dialogue_key])
	
	await dialogue_ui.dialogue_finished
	
	player.set_physics_process(true)

func release_player() -> void:
	player.set_physics_process(true)
	
	var tutorial_ui = get_node_or_null("Player/TutorialUI")
	if is_instance_valid(tutorial_ui):
		tutorial_ui.show_tutorial()

func _on_slanted_dialogue_box_dialogue_finished() -> void:
	player_cam.top_level = false
	player_cam.position = Vector2.ZERO
	
	if not anim_player.is_playing():
		anim_player.advance(0.1)
		anim_player.play()

func change_cam_intro() -> void:
	var intro_cam = get_node_or_null("IntroCamera")
	if is_instance_valid(intro_cam):
		intro_cam.make_current()

func change_cam_player() -> void:
	player_cam.make_current()
	
func change_cam_rafflesia() -> void:
	rafflesia_cam.make_current()
		
func bind_observation_path() -> void:
	observation_remote.remote_path = observation_remote.get_path_to(player)

func unbind_observation_path() -> void:
	observation_remote.remote_path = ""

func trigger_startle_effect() -> void:
	var tween: Tween = create_tween()
	
	tween.tween_property(player_cam, "offset", Vector2(5, 5), 0.05)
	tween.tween_property(player_cam, "offset", Vector2(-5, -5), 0.05)
	tween.tween_property(player_cam, "offset", Vector2(5, -5), 0.05)
	tween.tween_property(player_cam, "offset", Vector2.ZERO, 0.05)
	
	var step_back_pos: Vector2 = player.global_position + Vector2(0, 20) 
	tween.parallel().tween_property(player, "global_position", step_back_pos, 0.2)
	
	player.play_cutscene_animation("idle_down")

func _on_speaker_changed(speaker_name: String) -> void:
	var current_global_pos: Vector2 = player_cam.global_position
	
	player_cam.top_level = true 
	
	player_cam.global_position = current_global_pos
	
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
		
	cam_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if speaker_name == "Arnoldios":
		cam_tween.tween_property(player_cam, "global_position", rafflesia_cam.global_position, 0.5)
	else:
		cam_tween.tween_property(player_cam, "global_position", player.global_position, 0.5)
