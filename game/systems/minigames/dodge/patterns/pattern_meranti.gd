extends AttackPattern

## Scene untuk akar statis (root_hazard.tscn)
@export var root_hazard_scene: PackedScene

## Scene opsional jika ingin menembakkan proyektil lain di pattern ini
@export var bullet_scene: PackedScene

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var spawners: Node2D = $Spawners
@onready var reference_rect: ReferenceRect = get_node_or_null("ReferenceRect") as ReferenceRect

var player_node: Node2D = null
var hits_taken: int = 0


func _ready() -> void:
	player_node = get_tree().get_first_node_in_group("player")


func start_pattern() -> void:
	if anim_player and anim_player.has_animation("attack_sequence"):
		anim_player.play("attack_sequence")


func register_hit() -> void:
	hits_taken += 1


func finish_pattern() -> void:
	pattern_finished.emit(hits_taken)
	queue_free()


## Memunculkan akar dengan indikator preview di satu atau banyak Marker2D.
## Contoh marker_name_or_csv: "1" atau "1, 2, Target1"
func spawn_telegraph_root(marker_name_or_csv: String, preview_time: float = 0.8, strike_time: float = 0.4) -> void:
	if not root_hazard_scene:
		push_warning("spawn_telegraph_root GAGAL: Properti 'Root Hazard Scene' di Inspector belum diisi!")
		return

	var marker_list := marker_name_or_csv.split(",")

	for raw_name in marker_list:
		var m_name := raw_name.strip_edges()
		if m_name.is_empty():
			continue

		var marker := spawners.get_node_or_null(m_name) as Marker2D
		if not marker:
			push_warning("spawn_telegraph_root GAGAL: Marker '%s' tidak ditemukan di dalam Spawners!" % m_name)
			continue

		var root_obj = root_hazard_scene.instantiate()
		add_child(root_obj)
		root_obj.global_position = marker.global_position

		if root_obj.has_method("trigger"):
			root_obj.trigger(preview_time, strike_time)


## Menembak peluru lurus ke bawah dari marker
func spawn_from_marker(marker_name_or_csv: String, speed: float = 1200.0) -> void:
	if not bullet_scene:
		push_warning("spawn_from_marker GAGAL: Properti 'Bullet Scene' masih kosong!")
		return

	var marker_list := marker_name_or_csv.split(",")

	for raw_name in marker_list:
		var m_name := raw_name.strip_edges()
		if m_name.is_empty():
			continue

		var marker := spawners.get_node_or_null(m_name) as Marker2D
		if not marker:
			continue

		var bullet = bullet_scene.instantiate()
		add_child(bullet)
		bullet.global_position = marker.global_position
		bullet.direction = Vector2.DOWN
		bullet.base_speed = speed


## Menembak peluru yang mengarah langsung ke posisi player
func spawn_aimed_from_marker(marker_name_or_csv: String, speed: float = 1200.0) -> void:
	if not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")

	if not is_instance_valid(player_node):
		push_warning("spawn_aimed GAGAL: Player tidak ditemukan di group 'player'!")
		return

	if not bullet_scene:
		push_warning("spawn_aimed GAGAL: Properti 'Bullet Scene' masih kosong!")
		return

	var marker_list := marker_name_or_csv.split(",")

	for raw_name in marker_list:
		var m_name := raw_name.strip_edges()
		if m_name.is_empty():
			continue

		var marker := spawners.get_node_or_null(m_name) as Marker2D
		if not marker:
			continue

		var dir_to_player := marker.global_position.direction_to(player_node.global_position)
		var bullet = bullet_scene.instantiate()
		add_child(bullet)
		bullet.global_position = marker.global_position
		bullet.direction = dir_to_player
		bullet.base_speed = speed


## Menembak peluru dari Marker A menuju Marker B
func spawn_towards_marker(spawn_marker_csv: String, target_marker_name: String, speed: float = 1200.0) -> void:
	if not bullet_scene:
		push_warning("spawn_towards GAGAL: Properti 'Bullet Scene' masih kosong!")
		return

	var clean_target_name := target_marker_name.strip_edges()
	var target_marker := spawners.get_node_or_null(clean_target_name) as Marker2D
	if not target_marker:
		push_warning("spawn_towards GAGAL: Marker target '%s' tidak ditemukan!" % clean_target_name)
		return

	var spawn_list := spawn_marker_csv.split(",")

	for raw_name in spawn_list:
		var spawn_name := raw_name.strip_edges()
		if spawn_name.is_empty():
			continue

		var spawn_marker := spawners.get_node_or_null(spawn_name) as Marker2D
		if not spawn_marker:
			continue

		var dir_to_target := spawn_marker.global_position.direction_to(target_marker.global_position)
		var bullet = bullet_scene.instantiate()
		add_child(bullet)
		bullet.global_position = spawn_marker.global_position
		bullet.direction = dir_to_target
		bullet.base_speed = speed
