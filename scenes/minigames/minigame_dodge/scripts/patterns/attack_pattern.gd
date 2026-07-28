class_name AttackPattern
extends Node2D

signal pattern_finished(total_hits: int)

@export var pattern_duration: float = 6.0

var hits_received: int = 0
var is_active: bool = false
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_pattern_timeout)
	add_child(_timer)

func start_pattern() -> void:
	is_active = true
	_timer.start(pattern_duration)
	_on_pattern_started()

func register_hit() -> void:
	if not is_active:
		return
	hits_received += 1

func _on_pattern_started() -> void:
	pass

func _on_pattern_timeout() -> void:
	is_active = false
	pattern_finished.emit(hits_received)
	queue_free()
