extends AttackPattern

@export_group("Pengaturan Hujan Spora")
@export var spore_scene: PackedScene
@export var spawn_interval: float = 0.3
@export var bullet_travel_time: float = 2.5

@onready var spore_path: Path2D = $SporePath
@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	super._ready()
	assert(spore_scene != null, "ERROR: Masukkan resource spore_bullet.tscn ke Inspector!")
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_pattern_started() -> void:
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if not is_active:
		return
		
	var path_follower := PathFollow2D.new()
	path_follower.loop = false
	path_follower.rotates = false
	spore_path.add_child(path_follower)
	
	var bullet := spore_scene.instantiate()
	path_follower.add_child(bullet)
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(path_follower, "progress_ratio", 1.0, bullet_travel_time)
	tween.tween_callback(path_follower.queue_free)
