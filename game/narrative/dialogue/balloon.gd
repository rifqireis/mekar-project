extends CanvasLayer

enum CharacterCategory { HUMAN, BEAST, FLORA }

const CHAR_CATEGORIES: Dictionary = {
	"donga": CharacterCategory.HUMAN,
	"chicha": CharacterCategory.HUMAN,
	"chika": CharacterCategory.HUMAN,
	"orey": CharacterCategory.HUMAN,
	"warga kota": CharacterCategory.HUMAN,
	"warga": CharacterCategory.HUMAN,
	"pemuda": CharacterCategory.HUMAN,
	"freelancer": CharacterCategory.HUMAN,
	"nenek": CharacterCategory.HUMAN,
	"bossman": CharacterCategory.HUMAN,
	"mas ikal": CharacterCategory.HUMAN,
	"masikal": CharacterCategory.HUMAN,

	"azriel": CharacterCategory.BEAST,
	"nogura": CharacterCategory.BEAST,
	"g’hearld": CharacterCategory.BEAST,
	"g'hearld": CharacterCategory.BEAST,
	"ghearld": CharacterCategory.BEAST,
	"ular enggano": CharacterCategory.BEAST,
	"leonion": CharacterCategory.BEAST,
	"siamang": CharacterCategory.BEAST,

	"arnoldios": CharacterCategory.FLORA,
	"pohon meranti": CharacterCategory.FLORA,
	"meranti": CharacterCategory.FLORA,
	"rafflesia": CharacterCategory.FLORA
}

@export_group("Dialogue Box Textures")
@export var texture_human: Texture2D = preload("res://assets/ui/maphutan/donga_dialoguebox.png")
@export var texture_beast: Texture2D = preload("res://assets/ui/PanelContainerHewan.png")
@export var texture_flora: Texture2D = preload("res://assets/ui/PanelContainerFlora.png")

@export_group("Dialogue Settings")
@export var portraits: Dictionary[String, Texture2D] = {}
@export var character_voices: Dictionary[String, AudioStream] = {}
@export var character_pitches: Dictionary[String, float] = {}
@export var category_voices: Dictionary[String, AudioStream] = {}
@export var category_pitches: Dictionary[String, float] = {}
@export var default_voice: AudioStream = preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Low.mp3")
@export var default_pitch: float = 1.0
@export var pitch_randomness: float = 0.04
@export var voice_frequency: int = 2
@export var dialogue_resource: DialogueResource
@export var start_from_title: String = ""
@export var auto_start: bool = false
@export var will_block_other_input: bool = true
@export var next_action: StringName = &"ui_accept"
@export var skip_action: StringName = &"ui_cancel"

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress: Polygon2D = %Progress
@onready var panel_container: TextureRect = %PanelContainer if has_node("%PanelContainer") else null

var _current_voice_stream: AudioStream = null
var _current_base_pitch: float = 1.0
var _current_voice_step: int = 2

var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var locals: Dictionary = {}
var _locale: String = TranslationServer.get_locale()
var mutation_cooldown: Timer = Timer.new()

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

func _ready() -> void:
	balloon.hide()
	if not texture_human:
		texture_human = load("res://assets/ui/maphutan/donga_dialoguebox.png")
	if not texture_beast:
		texture_beast = load("res://assets/ui/PanelContainerHewan.png")
	if not texture_flora:
		texture_flora = load("res://assets/ui/PanelContainerFlora.png")
	if not panel_container and has_node("%PanelContainer"):
		panel_container = %PanelContainer
	elif not panel_container and has_node("Balloon/MarginContainer/PanelContainer"):
		panel_container = get_node("Balloon/MarginContainer/PanelContainer") as TextureRect

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if dialogue_label:
		dialogue_label.spoke.connect(_on_dialogue_label_spoke)
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()

func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")

func _unhandled_input(_event: InputEvent) -> void:
	if will_block_other_input:
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()

func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()

func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	update_portrait(dialogue_line.character)
	update_dialogue_box_texture(dialogue_line.character, dialogue_line.tags)
	update_typewriter_voice(dialogue_line.character, dialogue_line.tags)

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()

func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)

func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

func _clean_name(value: String) -> String:
	var s := value.to_lower().replace(" ", "").replace("_", "").replace("-", "").replace("'", "").replace("’", "")
	if s == "chicha":
		return "chika"
	return s

func get_character_category(character_name: String, tags: PackedStringArray = []) -> CharacterCategory:
	for tag in tags:
		var t := tag.to_lower()
		if t in ["flora", "tumbuhan", "tanaman"]:
			return CharacterCategory.FLORA
		elif t in ["beast", "satwa", "hewan"]:
			return CharacterCategory.BEAST
		elif t in ["human", "manusia"]:
			return CharacterCategory.HUMAN

	var clean := _clean_name(character_name)
	for key in CHAR_CATEGORIES:
		if _clean_name(key) == clean:
			return CHAR_CATEGORIES[key]

	return CharacterCategory.HUMAN

func update_dialogue_box_texture(character_name: String, tags: PackedStringArray = []) -> void:
	var box_node: TextureRect = panel_container
	if not box_node and has_node("%PanelContainer"):
		box_node = %PanelContainer
	if not box_node and has_node("Balloon/MarginContainer/PanelContainer"):
		box_node = get_node("Balloon/MarginContainer/PanelContainer") as TextureRect
	if not box_node:
		return

	var category := get_character_category(character_name, tags)
	match category:
		CharacterCategory.BEAST:
			if texture_beast:
				box_node.texture = texture_beast
		CharacterCategory.FLORA:
			if texture_flora:
				box_node.texture = texture_flora
		_:
			if texture_human:
				box_node.texture = texture_human

func update_portrait(character_name: String) -> void:
	var target := _clean_name(character_name)
	for child in balloon.get_children():
		if child is TextureRect or child is Sprite2D:
			if child.name in ["SlantedDialogueBox", "Background"]:
				continue
			if not target.is_empty() and _clean_name(child.name) == target:
				child.show()
			else:
				child.hide()

	if has_node("%Portrait"):
		var portrait_node = %Portrait as TextureRect
		if portraits.has(character_name):
			portrait_node.texture = portraits[character_name]
			portrait_node.show()
		elif character_name.is_empty():
			portrait_node.hide()

func update_typewriter_voice(character_name: String, tags: PackedStringArray = []) -> void:
	var clean := _clean_name(character_name)

	var stream_found: AudioStream = null
	var pitch_found: float = -1.0
	var step_found: int = voice_frequency

	for k in character_voices:
		if _clean_name(k) == clean:
			stream_found = character_voices[k]
			break

	for k in character_pitches:
		if _clean_name(k) == clean:
			pitch_found = character_pitches[k]
			break

	var category := get_character_category(character_name, tags)
	var cat_str := ""
	match category:
		CharacterCategory.HUMAN:
			cat_str = "human"
		CharacterCategory.BEAST:
			cat_str = "beast"
		CharacterCategory.FLORA:
			cat_str = "flora"

	if not stream_found:
		for k in category_voices:
			if k.to_lower() == cat_str:
				stream_found = category_voices[k]
				break

	if pitch_found < 0.0:
		for k in category_pitches:
			if k.to_lower() == cat_str:
				pitch_found = category_pitches[k]
				break

	if not stream_found:
		stream_found = _get_builtin_character_voice(clean, category)

	if pitch_found < 0.0:
		pitch_found = _get_builtin_character_pitch(clean, category)

	_current_voice_stream = stream_found if stream_found else default_voice
	_current_base_pitch = pitch_found if pitch_found > 0.0 else default_pitch
	_current_voice_step = step_found

func _get_builtin_character_voice(clean_name: String, category: CharacterCategory) -> AudioStream:
	match clean_name:
		"donga":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Low.mp3")
		"chika", "chicha":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Ascend.mp3")
		"orey":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Double.mp3")
		"bossman":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Low.mp3")
		"masikal":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Ascend.mp3")
		"nenek":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Meh.mp3")
		"pemuda", "warga", "wargakota", "freelancer":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Retro Low.mp3")
		"arnoldios", "meranti", "pohonmeranti", "rafflesia":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Garble Short 1.mp3")
		"ularenggano", "azriel", "nogura", "ghearld", "leonion", "siamang":
			return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Garble Short 2.mp3")
		_:
			match category:
				CharacterCategory.BEAST:
					return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Garble Short 2.mp3")
				CharacterCategory.FLORA:
					return preload("res://assets/sfx/Dialogue Sfx AmbroggioMusic/Garble Short 1.mp3")
				_:
					return default_voice

func _get_builtin_character_pitch(clean_name: String, category: CharacterCategory) -> float:
	match clean_name:
		"donga":
			return 1.00
		"chika", "chicha":
			return 1.30
		"orey":
			return 1.15
		"bossman":
			return 0.72
		"masikal":
			return 1.05
		"nenek":
			return 0.90
		"pemuda":
			return 1.10
		"freelancer":
			return 0.95
		"warga", "wargakota":
			return 1.00
		"arnoldios", "rafflesia":
			return 0.78
		"meranti", "pohonmeranti":
			return 0.70
		"ularenggano":
			return 0.65
		"azriel", "nogura", "leonion":
			return 0.75
		"siamang":
			return 1.20
		_:
			match category:
				CharacterCategory.BEAST:
					return 0.75
				CharacterCategory.FLORA:
					return 0.80
				_:
					return default_pitch

func _on_dialogue_label_spoke(letter: String, letter_index: int, _speed: float) -> void:
	if letter == " " or letter == "\n" or letter == "\t":
		return

	var step := _current_voice_step if _current_voice_step > 0 else 2
	if letter_index % step == 0 and audio_stream_player:
		var stream_to_play: AudioStream = _current_voice_stream if _current_voice_stream else audio_stream_player.stream
		if not stream_to_play:
			stream_to_play = default_voice
		if stream_to_play:
			audio_stream_player.stream = stream_to_play
			var r: float = pitch_randomness
			audio_stream_player.pitch_scale = _current_base_pitch * randf_range(1.0 - r, 1.0 + r)
			audio_stream_player.play()
