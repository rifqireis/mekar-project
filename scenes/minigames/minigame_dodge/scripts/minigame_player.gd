class_name MinigamePlayer
extends CharacterBody2D

signal hit

@export var move_speed: float = 500.0
var arena_bounds: Rect2 = Rect2()

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * move_speed
	move_and_slide()
	
	if arena_bounds.size != Vector2.ZERO:
		global_position.x = clamp(global_position.x, arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x)
		global_position.y = clamp(global_position.y, arena_bounds.position.y, arena_bounds.position.y + arena_bounds.size.y)

func set_bounds(bounds: Rect2) -> void:
	arena_bounds = bounds

func take_hit() -> void:
	hit.emit()
