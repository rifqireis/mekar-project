extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	monitoring = false
	if not body_entered.is_connected(_on_hit_player):
		body_entered.connect(_on_hit_player)

func trigger(preview_duration: float = 0.8, strike_duration: float = 0.4, fade_time: float = 0.25) -> void:
	monitoring = false
	sprite.modulate = Color(1.0, 0.3, 0.3, 0.35)

	var blink_tween := create_tween().set_loops(int(preview_duration / 0.2))
	blink_tween.tween_property(sprite, "modulate:a", 0.6, 0.1)
	blink_tween.tween_property(sprite, "modulate:a", 0.25, 0.1)

	await get_tree().create_timer(preview_duration).timeout
	if not is_inside_tree(): return
	if blink_tween.is_valid():
		blink_tween.kill()

	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	monitoring = true
	_check_overlapping()

	await get_tree().create_timer(strike_duration).timeout
	if not is_inside_tree(): return
	monitoring = false

	var fade_tween := create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	fade_tween.tween_callback(queue_free)

func _check_overlapping() -> void:
	for body in get_overlapping_bodies():
		_on_hit_player(body)
	for area in get_overlapping_areas():
		_on_hit_player(area)

func _on_area_entered(area: Area2D) -> void:
	_on_hit_player(area)

func _on_hit_player(other: Node2D) -> void:
	if not monitoring:
		return
	if other.is_in_group("player") or other.name == "MinigamePlayer" or other.name == "PlayerIcon" or other.is_in_group("player_hitbox"):
		if other.has_method("take_hit"):
			var was_invincible: bool = false
			if "is_invincible" in other:
				was_invincible = other.is_invincible
			other.take_hit()
			if not was_invincible:
				var pattern := _find_parent_pattern(self)
				if pattern:
					pattern.register_hit()
		elif other.get_parent() and other.get_parent().has_method("take_hit"):
			var parent: Node = other.get_parent()
			var was_invincible: bool = false
			if "is_invincible" in parent:
				was_invincible = parent.is_invincible
			parent.take_hit()
			if not was_invincible:
				var pattern := _find_parent_pattern(self)
				if pattern:
					pattern.register_hit()

func _find_parent_pattern(current_node: Node) -> AttackPattern:
	var parent := current_node.get_parent()
	while parent != null:
		if parent is AttackPattern:
			return parent as AttackPattern
		parent = parent.get_parent()
	return null
