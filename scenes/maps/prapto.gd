extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var dialogue_ui: TextureRect = $UIDialogueLayer/SlantedDialogueBox

var is_list_taken: bool = false

var dialogue_data: Dictionary = {
	"morning_part_1": [
		{"nama": "Chika", "teks": "Tumben udah bangun jam segini."},
		{"nama": "Donga", "teks": "Iya, mau cari udara segar sekalian."}
	],
	"morning_part_2": [
		{"nama": "Chika", "teks": "Pas banget. Sini, sekalian beliin titipanku di pasar."}
	],
	"morning_interact": [
		{"nama": "Chika", "teks": "Ini daftar belanjanya. Jangan sampai ada yang kelupaan ya."},
		{"nama": "Donga", "teks": "Oke, aku berangkat sekarang."}
	],
	"morning_idle": [
		{"nama": "Chika", "teks": "Hati-hati di jalan ya."}
	]
}

func _ready() -> void:
	
	if player.has_method("set_camera_zoom"):
		player.set_camera_zoom(6.0)

func trigger_dialogue(dialogue_key: String) -> void:
	anim_player.pause()
	dialogue_ui.start_dialogue(dialogue_data[dialogue_key])

func trigger_standalone_dialogue(dialogue_key: String) -> void:
	player.set_physics_process(false)
	dialogue_ui.start_dialogue(dialogue_data[dialogue_key])
	await dialogue_ui.dialogue_finished
	player.set_physics_process(true)

func _on_slanted_dialogue_box_dialogue_finished() -> void:
	var current_time = anim_player.current_animation_position
	
	print("Dialog selesai, mencoba melanjutkan animasi...")
	anim_player.play()
	print("Status animasi: ", anim_player.is_playing())
	
	anim_player.seek(current_time + 0.1, true)
	if not anim_player.is_playing():
		#anim_player.advance(0.1)
		anim_player.play()

func release_player() -> void:
	player.set_physics_process(true)
	if player.has_method("set_camera_zoom"):
		player.set_camera_zoom(4.5)
