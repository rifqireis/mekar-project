class_name MinigameArena
extends Node2D

signal minigame_finished(total_hits: int)

var arena_size: Vector2 = Vector2.ZERO

@onready var background: ColorRect = $Background
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var player: MinigamePlayer = $MinigamePlayer

var total_hits: int = 0
var is_playing: bool = false
var current_turn_index: int = 0

func _ready() -> void:
	_update_arena_bounds()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	if player.has_signal("hit"):
		player.hit.connect(_on_player_hit)

func _update_arena_bounds() -> void:
	arena_size = get_viewport_rect().size
	if background:
		background.size = arena_size
	if player and player.has_method("set_bounds"):
		player.set_bounds(Rect2(Vector2.ZERO, arena_size))

func _on_viewport_size_changed() -> void:
	_update_arena_bounds()
	if not is_playing and is_instance_valid(player):
		player.position = arena_size / 2.0

func start_phase(enemy_data: EnemyData, current_agitation: int) -> void:
	_update_arena_bounds()
	
	total_hits = 0
	is_playing = true
	if is_instance_valid(player):
		player.position = arena_size / 2.0
	
	for child in projectile_container.get_children():
		child.queue_free()
		
	var available_patterns: Array[PackedScene] = enemy_data.normal_patterns
	if current_agitation >= 50 and not enemy_data.rage_patterns.is_empty():
		available_patterns = enemy_data.rage_patterns
		
	if available_patterns.is_empty():
		push_error("ERROR: Array pola serangan pada resource musuh masih kosong!")
		_end_phase(0)
		return
		
	var selected_scene := available_patterns[current_turn_index % available_patterns.size()]
	current_turn_index += 1
	
	var pattern_instance := selected_scene.instantiate() as AttackPattern
	projectile_container.add_child(pattern_instance)
	
	pattern_instance.start_pattern()
	var hits_taken: int = await pattern_instance.pattern_finished
	
	_end_phase(hits_taken)

func _on_player_hit() -> void:
	if is_playing:
		total_hits += 1
		print("Player Hit! Total saat ini: ", total_hits)

func _end_phase(final_hits: int) -> void:
	if not is_playing:
		return
	is_playing = false
	
	for child in projectile_container.get_children():
		child.queue_free()
		
	minigame_finished.emit(final_hits)
