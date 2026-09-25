extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const MOVEMENT_SPEED: float = 100.0

var is_in_cutscene: bool = false

func _ready() -> void:
	add_to_group("player") 
	
	if PlayerRepository.should_restore_position:
		global_position = PlayerRepository.last_player_position
		PlayerRepository.should_restore_position = false

func _physics_process(_delta: float) -> void:
	if is_in_cutscene:
		return

func play_cutscene_animation(anim_name: String) -> void:
	is_in_cutscene = true
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
	is_in_cutscene = false
	animated_sprite.stop()

func activate_camera() -> void:
	$Camera2D.make_current()
	
func set_camera_zoom(cam_zoom: float) -> void:
	$Camera2D.zoom = Vector2(cam_zoom, cam_zoom)
	
