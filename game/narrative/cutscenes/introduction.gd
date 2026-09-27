extends Control

@onready var skip_button: Control = $SkipButton

var show_ui = false

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("all_bind")
		show_ui = true

	if Input.is_action_just_released("all_bind"):
		show_ui = false

	pressed_hud()

func _change_scene() -> void:
	SceneTransition.change_scene("res://game/world/bukit_kaba/bukit_kaba.tscn")

func _pressed_hud() -> void:
	if show_ui == true:
		skip_button.show()
	else:
		skip_button.hide()
