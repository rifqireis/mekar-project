extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Matikan deteksi tabrakan di awal
	monitoring = false

## Dipanggil saat spawn
func trigger(preview_duration: float = 0.8, strike_duration: float = 0.4, fade_time: float = 0.25) -> void:
	# =========================================================
	# FASE 1: PREVIEW / TELEGRAPH (Peringatan Transparan Merah)
	# =========================================================
	monitoring = false
	sprite.modulate = Color(1.0, 0.3, 0.3, 0.35) # Merah transparan
	
	# Efek kedip tipis sebagai aba-aba
	var blink_tween := create_tween().set_loops(int(preview_duration / 0.2))
	blink_tween.tween_property(sprite, "modulate:a", 0.6, 0.1)
	blink_tween.tween_property(sprite, "modulate:a", 0.25, 0.1)
	
	await get_tree().create_timer(preview_duration).timeout
	if not is_inside_tree(): return
	if blink_tween.is_valid():
		blink_tween.kill()

	# =========================================================
	# FASE 2: STRIKE (Render Penuh 100% & Hitbox Aktif)
	# =========================================================
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) # Warna normal penuh
	monitoring = true
	
	# Durasi akar aktif melukai player
	await get_tree().create_timer(strike_duration).timeout
	if not is_inside_tree(): return
	monitoring = false

	# =========================================================
	# FASE 3: FADE OUT & HAPUS
	# =========================================================
	var fade_tween := create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	fade_tween.tween_callback(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		var pattern = get_parent()
		if pattern and pattern.has_method("register_hit"):
			pattern.register_hit()
