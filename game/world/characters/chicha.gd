extends CharacterBody2D

@export var dialogue_resource: DialogueResource
@export var kitchen_marker: Marker2D
@export var walk_speed: float = 80.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var map_owner: Node2D = get_owner()

const MOVEMENT_SPEED: float = 100.0

var is_interacting: bool = false

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass
			
func interact(_interactor: Node = null) -> void:
	if is_interacting:
		return
		
	is_interacting = true
	
	var was_list_taken: bool = map_owner.is_list_taken
	
	DialogueManager.show_dialogue_balloon(dialogue_resource, "interact_chika", [map_owner])
	await DialogueManager.dialogue_ended
	
	if not was_list_taken and map_owner.is_list_taken:
		await move_to_kitchen()
		
	is_interacting = false

func move_to_kitchen() -> void:
	if not kitchen_marker:
		return

	animated_sprite.play("walk_up")	
	var distance: float = global_position.distance_to(kitchen_marker.global_position)
	var duration: float = distance / walk_speed
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "global_position", kitchen_marker.global_position, duration)
	
	await tween.finished
	
	animated_sprite.play("idle_down")
			
func play_cutscene_animation(anim_name: String) -> void:
	if anim_name == "walk_left":
		animated_sprite.flip_h = true
		animated_sprite.play("walk_right")
		return
	if anim_name == "idle_left":
		animated_sprite.flip_h = true
		animated_sprite.play("idle_right")
		return
	
	animated_sprite.flip_h = false
	animated_sprite.play(anim_name)
	
func stop_cutscene_animation() -> void:
	animated_sprite.stop()

func activate_camera() -> void:
	$Camera2D.make_current()
	
func set_camera_zoom(cam_zoom: float) -> void:
	$Camera2D.zoom = Vector2(cam_zoom, cam_zoom)
