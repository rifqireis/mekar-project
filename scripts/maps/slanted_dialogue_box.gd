extends TextureRect

signal dialogue_finished

@onready var log_text = $LogText
@onready var log_name = $LogName

var dialog_data: Array = []
var current_index: int = 0
var is_active: bool = false

func _ready():
	hide()

func start_dialogue(data: Array):
	dialog_data = data
	current_index = 0
	is_active = true
	show()
	tampilkan_baris()

func tampilkan_baris():
	if current_index < dialog_data.size():
		log_name.text = dialog_data[current_index]["nama"]
		log_text.text = dialog_data[current_index]["teks"]
	else:
		tutup_dialog()

func _input(event):
	if is_active and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		current_index += 1
		tampilkan_baris()

func tutup_dialog():
	is_active = false
	hide()
	emit_signal("dialogue_finished")
