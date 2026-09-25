extends CanvasLayer

@export var main_menu_scene_path: String = "res://game/ui/menus/main_menu.tscn"

@onready var color_rect: ColorRect = $ColorRect
@onready var texture_rect: TextureRect = $TextureRect

@onready var options: Array[Control] = [
	$TextureRect/Continue,
	$TextureRect/MainMenu,
	$TextureRect/Restart,
	$TextureRect/Exit
]

@onready var pointers: Array[Control] = [
	$TextureRect/Pointer1,
	$TextureRect/Pointer2,
	$TextureRect/Pointer3,
	$TextureRect/Pointer4
]

var current_index: int = 0
var is_menu_open: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_menu_open:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()
		return

	if not is_menu_open:
		return

	if event.is_action_pressed("walk_right") or event.is_action_pressed("ui_right"):
		_change_selection(1)
	elif event.is_action_pressed("walk_left") or event.is_action_pressed("ui_left"):
		_change_selection(-1)
	elif event.is_action_pressed("walk_down") or event.is_action_pressed("ui_down"):
		_change_selection(2)
	elif event.is_action_pressed("walk_up") or event.is_action_pressed("ui_up"):
		_change_selection(-2)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_execute_selected_option()

func open_menu() -> void:
	is_menu_open = true
	get_tree().paused = true
	show()
	current_index = 0
	_update_ui_visuals()

func close_menu() -> void:
	is_menu_open = false
	get_tree().paused = false
	hide()

func hide_menu() -> void:
	is_menu_open = false
	hide()

func _change_selection(offset: int) -> void:
	var new_index = current_index + offset
	if new_index >= 0 and new_index < options.size():
		current_index = new_index
		_update_ui_visuals()

func _update_ui_visuals() -> void:
	for i in range(options.size()):
		if i == current_index:
			options[i].modulate = Color(1.0, 1.0, 1.0, 1.0)
			if i < pointers.size() and pointers[i]:
				pointers[i].show()
		else:
			options[i].modulate = Color(0.4, 0.4, 0.4, 1.0)
			if i < pointers.size() and pointers[i]:
				pointers[i].hide()

func _execute_selected_option() -> void:
	match current_index:
		0:
			close_menu()
		1:
			get_tree().paused = false
			if ResourceLoader.exists(main_menu_scene_path):
				SceneTransition.change_scene(main_menu_scene_path)
			else:
				get_tree().change_scene_to_file(main_menu_scene_path)
		2:
			get_tree().paused = false
			var current_scene_path := get_tree().current_scene.scene_file_path
			if typeof(SceneTransition) != TYPE_NIL and SceneTransition.has_method("change_scene"):
				SceneTransition.change_scene(current_scene_path)
			else:
				get_tree().reload_current_scene()
		3:
			get_tree().quit()
