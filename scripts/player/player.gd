extends CharacterBody2D

@onready var ray_interact: RayCast2D = $RayInteract
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const MOVEMENT_SPEED: float = 100.0

func _ready() -> void:
	add_to_group("player") 
	
	if PlayerRepository.should_restore_position:
		global_position = PlayerRepository.last_player_position
		PlayerRepository.should_restore_position = false

func _physics_process(_delta: float) -> void:
	move_player()
			
	if ray_interact.is_colliding() and Input.is_action_just_pressed("interact"):
		var target: Node = ray_interact.get_collider()
		
		if target.has_method("interact"):
			target.interact(self)
		else:
			print("Target has no interact() method: ", target.name)

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
		
	move_and_slide()
	
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
