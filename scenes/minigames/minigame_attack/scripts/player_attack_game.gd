class_name PlayerAttackGame
extends Control

signal minigame_finished(damage_multiplier: float)

@export_group("Pengaturan Tingkat Kesulitan")
@export var base_cursor_speed: float = 500.0

@onready var background: ColorRect = $Background
@onready var target_zone: ColorRect = $TargetZone
@onready var cursor: ColorRect = $Cursor

var is_playing: bool = false
var current_speed: float = 0.0

var start_cursor_pos: Vector2 = Vector2.ZERO
var max_x_limit: float = 0.0
var target_center_x: float = 0.0
var target_half_width: float = 0.0

func _ready() -> void:
	start_cursor_pos = cursor.position
	
	max_x_limit = background.position.x + background.size.x
	
	target_center_x = target_zone.position.x + (target_zone.size.x / 2.0)
	target_half_width = target_zone.size.x / 2.0
	
	set_process(false)

func start_phase(speed_modifier: float = 1.0) -> void:
	cursor.position = start_cursor_pos
	
	current_speed = base_cursor_speed * maxf(0.5, speed_modifier)
	is_playing = true
	
	show()
	set_process(true)

func _process(delta: float) -> void:
	if not is_playing:
		return
		
	# Gerakkan kursor ke kanan
	cursor.position.x += current_speed * delta
	
	if cursor.position.x >= max_x_limit:
		_finish_minigame(true)

func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return
		
	var is_action_key: bool = event.is_action_pressed("ui_accept")
	var is_mouse_click: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	
	if is_action_key or is_mouse_click:
		_finish_minigame(false)
		get_viewport().set_input_as_handled()

func _finish_minigame(is_timeout: bool) -> void:
	is_playing = false
	set_process(false)
	
	var multiplier: float = 0.0
	
	if not is_timeout:
		# Hitung titik tengah kursor saat tombol ditekan
		var cursor_center_x: float = cursor.position.x + (cursor.size.x / 2.0)
		var distance: float = absf(cursor_center_x - target_center_x)
		
		# Jika kursor berhenti di dalam area kotak merah
		if distance <= target_half_width:
			var accuracy_ratio: float = 1.0 - (distance / target_half_width)
			multiplier = lerpf(0.5, 1.0, accuracy_ratio)
		else:
			multiplier = 0.0
			
	hide()
	minigame_finished.emit(multiplier)
