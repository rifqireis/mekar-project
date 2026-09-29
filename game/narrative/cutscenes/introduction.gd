extends Control

@onready var skip_button: TextureButton = $SkipButton

var hide_timer: SceneTreeTimer = null

func _ready() -> void:
	skip_button.hide()
	skip_button.modulate.a = 0.0

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("all_bind"):
		show_hud_temporary()

func _change_scene() -> void:
	SceneTransition.change_scene("res://game/world/bukit_kaba/bukit_kaba.tscn")

func show_hud_temporary() -> void:
	# Make the button visible and reset its opacity immediately
	skip_button.show()
	
	# Create a tween to fade in
	var tween = create_tween()
	tween.tween_property(skip_button, "modulate:a", 1.0, 0.2) # Fade in quickly over 0.2 seconds

	# Create a fresh 5-second countdown
	hide_timer = get_tree().create_timer(5.0)
	# Use .bind() or connect cleanly so previous signals don't conflict, 
	# or simply let the timer timeout trigger the fade out:
	if not hide_timer.timeout.is_connected(_fade_out_hud):
		hide_timer.timeout.connect(_fade_out_hud)
	
func _fade_out_hud() -> void:
	# Create a smooth fade-out tween
	var tween = create_tween()
	tween.tween_property(skip_button, "modulate:a", 0.0, 0.5) # Fade out over 0.5 seconds
	
	# Wait until the fade-out animation finishes, then actually hide it
	await tween.finished
	skip_button.hide()

func _on_skip_button_pressed() -> void:
	_change_scene()
	
func _on_animation_player_animation_finished(_anim_name: String) -> void:
	_change_scene()
