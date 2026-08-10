extends TextureRect

signal dialogue_finished

@onready var log_text: RichTextLabel = $LogText 
@onready var log_name: RichTextLabel = $LogName

const TYPING_SPEED: float = 0.03

var dialog_data: Array = []
var current_index: int = 0
var is_active: bool = false
var text_tween: Tween

func _ready() -> void:
	hide()

func start_dialogue(data: Array) -> void:
	dialog_data = data
	current_index = 0
	is_active = true
	show()
	display_current_line()

func display_current_line() -> void:
	if current_index < dialog_data.size():
		var current_line: Dictionary = dialog_data[current_index]
		log_name.text = current_line["nama"]
		log_text.text = current_line["teks"]
		
		log_text.visible_ratio = 0.0
		
		if text_tween and text_tween.is_valid():
			text_tween.kill()
			
		text_tween = create_tween()
		
		var duration: float = log_text.text.length() * TYPING_SPEED
		text_tween.tween_property(log_text, "visible_ratio", 1.0, duration)
	else:
		close_dialogue()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		
		if log_text.visible_ratio < 1.0:
			if text_tween and text_tween.is_valid():
				text_tween.kill()
			log_text.visible_ratio = 1.0
		
		else:
			current_index += 1
			display_current_line()

func close_dialogue() -> void:
	is_active = false
	hide()
	dialogue_finished.emit()
