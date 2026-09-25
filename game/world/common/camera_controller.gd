class_name CameraController
extends Node

@export var camera: Camera2D
@export var default_target: Node2D
@export var camera_targets: Dictionary[String, Node2D] = {}

var cam_tween: Tween

func _ready() -> void:
	if camera == null and default_target != null:
		camera = default_target.find_child("Camera2D", true, false) as Camera2D
	
	if camera:
		camera.top_level = true
		if default_target:
			camera.global_position = default_target.global_position
func focus_on(speaker_name: String, duration: float = 0.5) -> void:
	if not camera:
		return
		
	var target_node: Node2D = camera_targets.get(speaker_name, default_target)
	
	if not target_node:
		return

	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()

	cam_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	cam_tween.tween_property(camera, "global_position", target_node.global_position, duration)

func reset_to_player(duration: float = 0.5) -> void:
	focus_on("", duration)

func release_to_player(duration: float = 0.5) -> void:
	if not camera or not default_target:
		return

	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()

	cam_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	cam_tween.tween_property(camera, "global_position", default_target.global_position, duration)
	
	cam_tween.tween_callback(func():
		camera.top_level = false
		camera.position = Vector2.ZERO
	)
