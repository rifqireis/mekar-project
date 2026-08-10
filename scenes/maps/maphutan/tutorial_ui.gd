extends CanvasLayer

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var is_active: bool = false

func _ready() -> void:
	hide()
	if has_node("MarginContainer"):
		$MarginContainer.modulate.a = 0.0

func show_tutorial() -> void:
	show()
	anim_player.play("fade_in")
	
	await anim_player.animation_finished
	
	is_active = true

func _input(event: InputEvent) -> void:
	if is_active:
		if event.is_action_pressed("walk_up") or \
		   event.is_action_pressed("walk_down") or \
		   event.is_action_pressed("walk_left") or \
		   event.is_action_pressed("walk_right") or \
		   event.is_action_pressed("interact_action"):
			
			is_active = false
			anim_player.play("fade_out")
