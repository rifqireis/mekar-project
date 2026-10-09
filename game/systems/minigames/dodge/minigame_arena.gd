class_name MinigameArena
extends Node2D

signal minigame_finished(total_hits: int)

var arena_size: Vector2 = Vector2.ZERO

@onready var background: Panel = $Background
@onready var texture_rect: TextureRect = get_node_or_null("TextureRect")
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var player: MinigamePlayer = $MinigamePlayer
@onready var audio_stream_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer") if has_node("AudioStreamPlayer") else get_node_or_null("HitSFX")

var total_hits: int = 0
var is_playing: bool = false
var current_turn_index: int = 0

var _shake_tween: Tween
var _shake_targets: Array[CanvasItem] = []
var _base_positions: Array[Vector2] = []

func _ready() -> void:
	_update_arena_bounds()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	if player.has_signal("hit"):
		player.hit.connect(_on_player_hit)

	_setup_shake_targets()

func _setup_shake_targets() -> void:
	_shake_targets.clear()
	_base_positions.clear()

	var parent := get_parent()
	if parent is SubViewport:
		var grand_parent := parent.get_parent()
		if grand_parent is SubViewportContainer:
			_shake_targets.append(grand_parent)
			_base_positions.append(grand_parent.position)

			var great_grand_parent := grand_parent.get_parent()
			if great_grand_parent:
				var decor := great_grand_parent.get_node_or_null("ArenaDecoration") as CanvasItem
				if decor:
					_shake_targets.append(decor)
					_base_positions.append(decor.position)

	if _shake_targets.is_empty():
		_shake_targets.append(self)
		_base_positions.append(position)

func _reset_shake_positions() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	for i in range(_shake_targets.size()):
		_shake_targets[i].position = _base_positions[i]

func _update_arena_bounds() -> void:
	arena_size = get_viewport_rect().size
	if player and player.has_method("set_bounds"):
		player.set_bounds(Rect2(Vector2.ZERO, arena_size))

func _on_viewport_size_changed() -> void:
	_update_arena_bounds()
	if not is_playing and is_instance_valid(player):
		player.position = arena_size / 2.0

func start_phase(enemy_data: EnemyData, current_agitation: int) -> void:
	_update_arena_bounds()

	_setup_shake_targets()
	_reset_shake_positions()

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
		_shake_arena()
		_play_hit_sfx()

func _shake_arena() -> void:
	if _shake_targets.is_empty():
		_setup_shake_targets()

	_reset_shake_positions()

	var offsets: Array[Vector2] = [
		Vector2(16, 0),
		Vector2(-16, 0),
		Vector2(8, 0),
		Vector2(-8, 0),
		Vector2.ZERO
	]

	_shake_tween = create_tween()
	for offset in offsets:
		for i in range(_shake_targets.size()):
			var target := _shake_targets[i]
			var target_pos := _base_positions[i] + offset
			if i == 0:
				_shake_tween.chain().tween_property(target, "position", target_pos, 0.06)
			else:
				_shake_tween.parallel().tween_property(target, "position", target_pos, 0.06)

func _play_hit_sfx() -> void:
	var sfx: AudioStreamPlayer = audio_stream_player
	if not sfx and is_instance_valid(player) and player.has_node("AudioStreamPlayer"):
		sfx = player.get_node_or_null("AudioStreamPlayer")
	if sfx and sfx.stream != null:
		sfx.play()

func _end_phase(final_hits: int) -> void:
	if not is_playing:
		return
	is_playing = false

	_reset_shake_positions()

	for child in projectile_container.get_children():
		child.queue_free()

	minigame_finished.emit(final_hits)
