extends Area2D

@export var base_speed: float = 180.0
@export var speed_curve: Curve
@export var sway_amplitude: float = 20.0  
@export var sway_frequency: float = 4.0   

var direction: Vector2 = Vector2.DOWN
var life_time: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_hit_player)
	body_entered.connect(_on_hit_player)

func _process(delta: float) -> void:
	life_time += delta
	
	var current_speed = base_speed
	if speed_curve:
		var curve_factor = speed_curve.sample(clamp(life_time, 0.0, 1.0))
		current_speed = base_speed * curve_factor
		
	var forward_motion = direction * current_speed * delta
	var perpendicular_dir = Vector2(-direction.y, direction.x)
	var sway_offset = perpendicular_dir * sin(life_time * sway_frequency) * sway_amplitude * delta
	
	position += forward_motion + sway_offset

func _on_hit_player(other: Node2D) -> void:
	if other.is_in_group("player") or other.name == "MinigamePlayer" or other.name == "PlayerIcon":
		if other.has_method("take_hit"):
			var was_invincible: bool = false
			if "is_invincible" in other:
				was_invincible = other.is_invincible
			
			other.take_hit()
			
			if not was_invincible:
				var pattern := _find_parent_pattern(self)
				if pattern:
					pattern.register_hit()
		
		queue_free()

func _find_parent_pattern(current_node: Node) -> AttackPattern:
	var parent := current_node.get_parent()
	while parent != null:
		if parent is AttackPattern:
			return parent as AttackPattern
		parent = parent.get_parent()
	return null
