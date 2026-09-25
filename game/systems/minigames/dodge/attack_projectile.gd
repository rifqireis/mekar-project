class_name AttackProjectile
extends Area2D

@export var speed: float = 150.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func setup(start_position: Vector2, target_direction: Vector2) -> void:
	global_position = start_position
	direction = target_direction.normalized()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is MinigamePlayer:
		if body.has_method("take_hit"):
			body.take_hit()
		queue_free()
