extends CharacterBody2D

@onready var ray_interact: RayCast2D = $RayInteract
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var walking_sfx: AudioStreamPlayer = $walking_sfx
@onready var interact_prompt: Sprite2D = $InteractPrompt

const MOVEMENT_SPEED: float = 100.0

var is_in_cutscene: bool = false


var target_prompt_scale: Vector2 = Vector2.ONE
var is_prompt_shown: bool = false
var prompt_tween: Tween = null

func _ready() -> void:
	add_to_group("player") 
	
	if PlayerRepository.should_restore_position:
		global_position = PlayerRepository.last_player_position
		PlayerRepository.should_restore_position = false

	if interact_prompt:
		target_prompt_scale = interact_prompt.scale
		interact_prompt.visible = false
		interact_prompt.scale = Vector2.ZERO
		interact_prompt.z_index = 100

func _physics_process(_delta: float) -> void:
	if is_in_cutscene:
		_hide_prompt()
		return
		
	move_player()
	_handle_interaction()

			
func move_player() -> void:
	var direction: Vector2 = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = direction * MOVEMENT_SPEED

	if direction != Vector2.ZERO:
		if direction.x != 0:
			if direction.x > 0:
				animated_sprite.animation = "walk_right"
				animated_sprite.flip_h = false
				ray_interact.target_position = Vector2(20, 0)
			elif direction.x < 0:
				animated_sprite.animation = "walk_right"
				animated_sprite.flip_h = true
				ray_interact.target_position = Vector2(-20, 0)
		else:
			if direction.y > 0:
				animated_sprite.animation = "walk_down"
				ray_interact.target_position = Vector2(0, 20)
			elif direction.y < 0:
				animated_sprite.animation = "walk_up"
				ray_interact.target_position = Vector2(0, -20)
		animated_sprite.play()
	else:
		animated_sprite.stop()
		walking_sfx.play()
	move_and_slide()
	
func play_cutscene_animation(anim_name: String) -> void:
	is_in_cutscene = true
	_hide_prompt()
	
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


func _handle_interaction() -> void:
	var can_interact := false
	var target: Node = null

	if ray_interact.is_colliding():
		target = ray_interact.get_collider()
		if target and target.has_method("interact"):
			can_interact = true

	if can_interact:
		_show_prompt()
		if Input.is_action_just_pressed("interact"):
			target.interact(self)
	else:
		_hide_prompt()
	
func _show_prompt() -> void:
	if is_prompt_shown or not interact_prompt:
		return
	is_prompt_shown = true
	
	if prompt_tween and prompt_tween.is_running():
		prompt_tween.kill()

	interact_prompt.visible = true
	prompt_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	prompt_tween.tween_property(interact_prompt, "scale", target_prompt_scale, 0.2)
		
func _hide_prompt() -> void:
	if not is_prompt_shown or not interact_prompt:
		return
	is_prompt_shown = false

	if prompt_tween and prompt_tween.is_running():
		prompt_tween.kill()

	prompt_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	prompt_tween.tween_property(interact_prompt, "scale", Vector2.ZERO, 0.15)
	prompt_tween.chain().tween_callback(func(): interact_prompt.visible = false)
