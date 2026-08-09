extends Node2D

@onready var player = $Player
@onready var dialogue_ui = $UIDialogueLayer/SlantedDialogueBox
@onready var anim_player = $AnimationPlayer # Pastikan path ini benar


# Gabungkan naskah ke dalam satu Dictionary agar mudah dipanggil
var daftar_naskah = {
	"pendaratan": [
		{"nama": "Donga", "teks": "Suspect 18. Mutasi Raflesia."},
		{"nama": "Donga", "teks": "Kalau lancar, aku besok udah bisa pulang ke-rumah. Orey pasti nanya lagi soal luka di lenganku yang kemarin."},
		{"nama": "Donga", "teks": "Aduduh, Fokus dulu. Nanti aja bayanginnya."}
	],
	"investigasi": [
		{"nama": "Donga", "teks": "Bukan sisa perkelahian. Ini ditandain."},
		{"nama": "Donga", "teks": "Dan lebih besar dari yang tertulis di laporan."}
	],
	"konfrontasi": [
		{"nama": "Donga", "teks": "Target teridentifikasi."},
		{"nama": "Arnoldios", "teks": "Kalian cabut akarku dari tanah ini. Kalian bakar rumahku buat batu dan besi. Sekarang kalian masih berdiri di sisa-sisanya."}
	]
}

func _ready():
	player.set_physics_process(false)

func picu_dialog(kunci_naskah: String):
	anim_player.pause() 
	dialogue_ui.start_dialogue(daftar_naskah[kunci_naskah])

func lepaskan_pemain():
	player.set_physics_process(true)
	var wasd = get_node_or_null("Player/TutorialWASD")
	if is_instance_valid(wasd):
		wasd.tampilkan_indikator()


func _on_slanted_dialogue_box_dialogue_finished():
	if anim_player.is_playing() == false:
		anim_player.play()


@onready var cinematic_camera = $CinematicCamera
@onready var spot_investigasi = $SpotInvestigasi

var posisi_sebelum_investigasi: Vector2 

func _on_investigation_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player.set_physics_process(false)
		
		posisi_sebelum_investigasi = player.global_position
		
		anim_player.play("transisi_investigasi")
		
		if has_node("InvestigationArea"):
			$InvestigationArea.set_deferred("monitoring", false)
			$InvestigationArea.queue_free()

func pindah_ke_set_investigasi():
	player.global_position = spot_investigasi.global_position

	cinematic_camera.make_current()

func kembali_ke_posisi_awal():
	player.global_position = posisi_sebelum_investigasi
	
	player.get_node("Camera2D").make_current()

func selesai_investigasi():
	player.set_physics_process(true)
	if is_instance_valid(cinematic_camera):
		cinematic_camera.queue_free()
		
func change_cam_player():
	$Player/Camera2D.make_current()
	
func change_cam_investigation():
	$InvestigationCamera.make_current()
