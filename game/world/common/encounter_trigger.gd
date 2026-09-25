extends Area2D

@export_group("Konfigurasi Encounter")
@export var enemy_resource: EnemyData
@export var instant_trigger: bool = false

var is_player_inside: bool = false
var player_node: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	assert(enemy_resource != null, "ERROR: Masukkan file EnemyData (.tres) pada pemicu ini di Inspector!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_inside = true
		player_node = body
		
		if instant_trigger:
			_trigger_battle()
		else:
			print("Tekan tombol interaksi untuk memeriksa anomali.")

func _on_body_exited(body: Node2D) -> void:
	if body == player_node:
		is_player_inside = false
		player_node = null


func _trigger_battle() -> void:
	if not player_node:
		print("ERROR BATTLE: player_node masih null! Transisi dibatalkan.")
		return
	
	var current_map_path := get_tree().current_scene.scene_file_path
	
	PlayerRepository.start_battle(enemy_resource, player_node.global_position, current_map_path)

func interact(initiator: Node2D = null) -> void:
	print("Interaksi dari RayInteract diterima!")
	if initiator:
		player_node = initiator
	_trigger_battle()
