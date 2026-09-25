class_name MinigamePlayer
extends CharacterBody2D

signal hit

@export var move_speed: float = 500.0
@export var iframe_duration: float = 0.8

var arena_bounds: Rect2 = Rect2()
var is_invincible: bool = false

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_vector * move_speed
	move_and_slide()
	
	if arena_bounds.size != Vector2.ZERO:
		global_position.x = clamp(global_position.x, arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x)
		global_position.y = clamp(global_position.y, arena_bounds.position.y, arena_bounds.position.y + arena_bounds.size.y)

func set_bounds(bounds: Rect2) -> void:
	arena_bounds = bounds

func take_hit() -> void:
	if is_invincible:
		return
		
	is_invincible = true
	hit.emit()
	_play_iframe_animation()

func _play_iframe_animation() -> void:
	var loop_count := int(iframe_duration / 0.1)
	var tween := create_tween().set_loops(loop_count)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.2), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.05)
	
	await tween.finished
	is_invincible = false
	modulate = Color(1, 1, 1, 1.0)
