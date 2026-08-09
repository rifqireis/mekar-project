extends CharacterBody2D

@onready var ray_interact : RayCast2D = $RayInteract
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

const VELOCITY = 100

func _ready() -> void:
	add_to_group("player") 
	
	if PlayerRepository.should_restore_position:
		global_position = PlayerRepository.last_player_position
		PlayerRepository.should_restore_position = false

func _physics_process(_delta: float) -> void:
	move_player(_delta)
			
	if ray_interact.is_colliding() and Input.is_action_just_pressed("interact"):
		print("kena")
		var target = ray_interact.get_collider()
		
		if target.has_method("interact"):
			target.interact(self)
		else:
			print("Objek yang ditabrak tidak memiliki fungsi interact(): ", target.name)

func move_player(_delta):
	var direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = direction * VELOCITY

	# set animasi
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
	
	
func putar_animasi_cutscene(nama_animasi: String):
	animated_sprite.play(nama_animasi)
	
func hentikan_animasi_cutscene():
	animated_sprite.stop()

func set_cam():
	$Camera2D.make_current()
