extends Area2D

@export var enemy_data: EnemyData

func interact(player_node: Node2D = null) -> void:
	if not enemy_data:
		push_error("ERROR: File enemy_data (.tres) belum dimasukkan ke Inspector Ular Enggano!")
		return

	var player_pos: Vector2 = global_position
	if is_instance_valid(player_node):
		player_pos = player_node.global_position

	PlayerRepository.start_battle(
		enemy_data,
		player_pos,
		get_tree().current_scene.scene_file_path
	)
