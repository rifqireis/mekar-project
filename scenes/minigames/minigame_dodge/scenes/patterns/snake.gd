extends Area2D

@export var base_speed: float = 1200.0
var direction: Vector2 = Vector2.DOWN

var is_curved: bool = false
var p0: Vector2
var p1: Vector2
var p2: Vector2
var travel_time: float = 1.0
var elapsed_time: float = 0.0

func _ready() -> void:
	var notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	if notifier:
		notifier.screen_exited.connect(queue_free)

func start_curved_path(start_pos: Vector2, curve_pos: Vector2, end_pos: Vector2, duration: float = 1.0) -> void:
	p0 = start_pos
	p1 = curve_pos
	p2 = end_pos
	travel_time = duration
	elapsed_time = 0.0
	global_position = start_pos
	is_curved = true

func _physics_process(delta: float) -> void:
	if is_curved:
		elapsed_time += delta
		var t: float = clampf(elapsed_time / travel_time, 0.0, 1.0)

		var q0 := p0.lerp(p1, t)
		var q1 := p1.lerp(p2, t)
		var next_pos := q0.lerp(q1, t)

		if global_position != next_pos:
			rotation = (next_pos - global_position).angle()

		global_position = next_pos

		if t >= 1.0:
			queue_free()
	else:
		global_position += direction * base_speed * delta
		rotation = direction.angle()
