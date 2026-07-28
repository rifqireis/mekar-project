extends Node

var hp: int = 100
var max_hp: int = 100
var str: int = 15

var current_enemy: EnemyData = null
var last_map_scene: String = "res://scenes/maps/world.tscn"
var last_player_position: Vector2 = Vector2.ZERO

var should_restore_position: bool = false


func take_damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, max_hp)

func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)

func reset_player_data() -> void:
	hp = max_hp
	str = 15
	last_player_position = Vector2.ZERO

func start_battle(enemy_resource: EnemyData, player_pos: Vector2, current_map_path: String) -> void:
	current_enemy = enemy_resource
	last_player_position = player_pos
	last_map_scene = current_map_path
	
	get_tree().change_scene_to_file("res://scenes/battle/battle_ui.tscn")

func end_battle(victory: bool = true) -> void:
	current_enemy = null
	should_restore_position = true
	
	if last_map_scene != "":
		get_tree().change_scene_to_file(last_map_scene)
	else:
		print("ERROR: last_map_scene kosong! Kembali ke default world.")
		get_tree().change_scene_to_file("res://scenes/maps/world.tscn")
