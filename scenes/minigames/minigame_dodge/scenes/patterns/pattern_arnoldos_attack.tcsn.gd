extends AttackPattern

@export var bullet_scene: PackedScene

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var spawners: Node2D = $Spawners

var player_node: Node2D = null
var hits_taken: int = 0

func _ready() -> void:
	player_node = get_tree().get_first_node_in_group("player")

func start_pattern() -> void:
	if anim_player.has_animation("attack_sequence"):
		anim_player.play("attack_sequence")

func register_hit() -> void:
	hits_taken += 1

func finish_pattern() -> void:
	pattern_finished.emit(hits_taken)
	queue_free()

func spawn_from_marker(marker_name_or_csv: String, speed: float = 1200.0) -> void:
	var marker_list = marker_name_or_csv.split(",")
	
	for raw_name in marker_list:
		var m_name = raw_name.strip_edges() 
		if m_name.is_empty(): continue
		
		var marker = spawners.get_node_or_null(m_name) as Marker2D
		if not marker or not bullet_scene:
			push_warning("spawn_from_marker gagal: Marker '%s' atau bullet_scene tidak valid!" % m_name)
			continue

		var bullet = bullet_scene.instantiate()
		add_child(bullet)    
		bullet.global_position = marker.global_position     
		bullet.direction = Vector2.DOWN
		bullet.base_speed = speed


func spawn_aimed_from_marker(marker_name_or_csv: String, speed: float = 1200.0) -> void:
	if not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
	
	if not is_instance_valid(player_node):
		push_warning("spawn_aimed GAGAL: Player tidak ditemukan di group 'player'!")
		return

	if not bullet_scene:
		push_warning("spawn_aimed GAGAL: Properti 'Bullet Scene' di Inspector Pattern masih kosong!")
		return

	var marker_list = marker_name_or_csv.split(",")

	for raw_name in marker_list:
		var m_name = raw_name.strip_edges() 
		if m_name.is_empty(): 
			continue

		var marker = spawners.get_node_or_null(m_name) as Marker2D
		if not marker:
			push_warning("spawn_aimed GAGAL: Node Marker '%s' tidak ditemukan di Spawners!" % m_name)
			continue

		# spawn
		var dir_to_player = marker.global_position.direction_to(player_node.global_position)
		var bullet = bullet_scene.instantiate()
		add_child(bullet)    

		bullet.global_position = marker.global_position    
		bullet.direction = dir_to_player
		bullet.base_speed = speed

func spawn_towards_marker(spawn_marker_csv: String, target_marker_name: String, speed: float = 1200.0) -> void:
	if not bullet_scene:
		push_warning("spawn_towards GAGAL: Properti 'Bullet Scene' di Inspector Pattern masih kosong!")
		return

	var clean_target_name = target_marker_name.strip_edges()
	var target_marker = spawners.get_node_or_null(clean_target_name) as Marker2D
	if not target_marker:
		push_warning("spawn_towards GAGAL: Marker target '%s' tidak ditemukan di Spawners!" % clean_target_name)
		return

	var spawn_list = spawn_marker_csv.split(",")

	for raw_name in spawn_list:
		var spawn_name = raw_name.strip_edges()
		if spawn_name.is_empty(): 
			continue

		var spawn_marker = spawners.get_node_or_null(spawn_name) as Marker2D
		if not spawn_marker:
			
			push_warning("spawn_towards GAGAL: Marker asal '%s' tidak ditemukan di Spawners!" % spawn_name)
			continue

		var dir_to_target = spawn_marker.global_position.direction_to(target_marker.global_position)
		
		var bullet = bullet_scene.instantiate()
		add_child(bullet)

		bullet.global_position = spawn_marker.global_position
		bullet.direction = dir_to_target
		bullet.base_speed = speed
