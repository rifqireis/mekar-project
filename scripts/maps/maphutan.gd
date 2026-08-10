extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var dialogue_ui: TextureRect = $UIDialogueLayer/SlantedDialogueBox
@onready var anim_player: AnimationPlayer = $AnimationPlayer

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
	"investigation": [
		{"nama": "Donga", "teks": "Bukan sisa perkelahian. Ini ditandain."},
		{"nama": "Donga", "teks": "Dan lebih besar dari yang tertulis di laporan."}
	],
	"confrontation": [
		{"nama": "Donga", "teks": "Target teridentifikasi."},
		{"nama": "Arnoldios", "teks": "Kalian cabut akarku dari tanah ini. Kalian bakar rumahku buat batu dan besi. Sekarang kalian masih berdiri di sisa-sisanya."}
	]
}

func _ready() -> void:
	player.set_physics_process(false)

func trigger_dialogue(dialogue_key: String) -> void:
	anim_player.pause() 
	dialogue_ui.start_dialogue(dialogue_data[dialogue_key])

func release_player() -> void:
	player.set_physics_process(true)
	
	var tutorial_ui = get_node_or_null("Player/TutorialUI")
	if is_instance_valid(tutorial_ui):
		tutorial_ui.show_tutorial()

func _on_slanted_dialogue_box_dialogue_finished() -> void:
	if not anim_player.is_playing():
		anim_player.advance(0.1)
		anim_player.play()

func change_cam_intro() -> void:
	var intro_cam = get_node_or_null("IntroCamera")
	if is_instance_valid(intro_cam):
		intro_cam.make_current()

func change_cam_player() -> void:
	var player_cam = get_node_or_null("Player/Camera2D")
	if is_instance_valid(player_cam):
		player_cam.make_current()
