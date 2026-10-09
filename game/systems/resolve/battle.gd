extends Control

enum BattleMode { ACTION, DIALOGUE, MINIGAME }
var current_mode: BattleMode = BattleMode.DIALOGUE
enum BattleState { START_BATTLE, PLAYER_TURN, ENEMY_TURN, END_BATTLE }
var current_state: BattleState = BattleState.START_BATTLE

var is_tree_enemy: bool = false
var is_tree_enraged: bool = false

@export var tree_mad_enemy_resource: EnemyData = preload("res://data/enemies/meranti_enraged.tres")
@export var dialogue_resource: DialogueResource
@export var enemy_resource: EnemyData
@export var snake_enemy_resource: EnemyData = preload("res://data/enemies/ular_enggano.tres")

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
@export var battle_texture_human: Texture2D = preload("res://assets/ui/battle/main/textbox.png")
@export var battle_texture_beast: Texture2D = preload("res://assets/ui/PanelContainerHewan.png")
@export var battle_texture_flora: Texture2D = preload("res://assets/ui/PanelContainerFlora.png")

@export_group("Enemy Stats Card")
@export var enemy_card_placeholder: Texture2D = preload("res://assets/ui/battle/main/enemy_card_placeholder.png")

@export_group("Pengaturan Jeda Dialog")
@export var default_dialogue_delay: float = 2.0

@export_group("Set ModeMinigame")
@export var enemy_dialogue_offset: Vector2 = Vector2(0.0, -60.0)
@export var enemy_minigame_offset: Vector2 = Vector2(0.0, -120.0)

var enemy_sprite_clone: AnimatedSprite2D = null

@export_group("Pengaturan Animasi UI")
@export var anim_duration: float = 0.25
@export var anim_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var anim_ease: Tween.EaseType = Tween.EASE_OUT

@onready var enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var floating_bar: Control = $FloatingBar
@onready var slanted_dialogue_box: Control = $Mode_Dialogue/SlantedDialogueBox
@onready var log_text: RichTextLabel = $Mode_Dialogue/SlantedDialogueBox/LogText
@onready var speaker_name: RichTextLabel = $Mode_Dialogue/SlantedDialogueBox/LogName

@onready var mode_action: Control = $Mode_Action
@onready var mode_dialogue: Control = $Mode_Dialogue
@onready var mode_minigame: Control = $Mode_Minigame

@onready var enemy_attack_container: SubViewportContainer = $Mode_Minigame/SubViewportContainer
@onready var enemy_attack_game: MinigameArena = $Mode_Minigame/SubViewportContainer/SubViewport/MinigameArena
@onready var player_attack_game: PlayerAttackGame = $Mode_Minigame/PlayerAttackGame

@onready var action_menu: Control = $Mode_Action/MainButtonContainer
@onready var sub_action_panel: TextureRect = $Mode_Action/SubActionPanel
@onready var suppress_box: Control = $Mode_Action/SubActionPanel/SuppressBox
@onready var observe_box: Control = $Mode_Action/SubActionPanel/ObserveBox
@onready var engage_box: Control = $Mode_Action/SubActionPanel/EngageBox
@onready var adapt_box: Control = $Mode_Action/SubActionPanel/AdaptBox
@onready var indication_arrow: TextureRect = $Mode_Action/SubActionPanel.get_node_or_null("IndicationArrow")

var _sub_action_index: int = 0
var _main_button_index: int = 0
var _arrow_tween: Tween

@onready var player_hp_bar: ProgressBar = $FloatingBar/PlayerProfile/HPBar
@onready var player_str_bar: ProgressBar = $FloatingBar/PlayerProfile.get_node_or_null("STRBar")
@onready var enemy_stats: TextureRect = $FloatingBar/EnemyStats
@onready var enemy_cards_rect: TextureRect = $FloatingBar/EnemyStats.get_node_or_null("EnemyCards")
@onready var enemy_hp_bar: ProgressBar = $FloatingBar/EnemyStats.find_child("HPBar", true, false) as ProgressBar
@onready var enemy_agt_bar: ProgressBar = $FloatingBar/EnemyStats.find_child("AgitationBar", true, false) as ProgressBar
@onready var enemy_icon_rect: TextureRect = $FloatingBar/EnemyStats.find_child("EnemyIcon", true, false) as TextureRect
@onready var enemy_name_label: Label = $FloatingBar/EnemyStats.find_child("EnemyName", true, false) as Label
@onready var trust_bar: TextureProgressBar = $FloatingBar/StandaloneTrustBar
@onready var stability_bar: TextureProgressBar = $FloatingBar/StandaloneStabilityBar
@onready var arena_decoration: TextureRect = $Mode_Minigame/ArenaDecoration

@onready var tutorial_panel: Control = $TutorialPanel
@onready var dodge_panel: Control = $TutorialPanel/DodgePanel
@onready var attack_panel: Control = $TutorialPanel/AttackPanel
@onready var engage_panel: Control = $TutorialPanel/EngagePanel
@onready var observe_panel: Control = $TutorialPanel/ObservePanel
@onready var suppress_panel: Control = $TutorialPanel.get_node_or_null("SuppressPanel")

var is_first_suppress_tutorial: bool = true
var is_first_attack_tutorial: bool = true
var is_first_dodge_tutorial: bool = true
var is_first_mad_tree_observe_hint: bool = false
var is_first_mad_tree_engage_hint: bool = false

var default_enemy_pos: Vector2 = Vector2.ZERO
var enemy_hp: int = 100
var enemy_trust: int = 0
var enemy_stability: int = 0
var enemy_agitation: int = 0
var observe_count: int = 0

func _ready() -> void:
	await get_tree().process_frame

	if not battle_texture_human:
		battle_texture_human = load("res://assets/ui/battle/main/textbox.png")
	if not battle_texture_beast:
		battle_texture_beast = load("res://assets/ui/PanelContainerHewan.png")
	if not battle_texture_flora:
		battle_texture_flora = load("res://assets/ui/PanelContainerFlora.png")
	if not enemy_card_placeholder:
		enemy_card_placeholder = load("res://assets/ui/battle/main/enemy_card_placeholder.png")

	_reset_main_buttons_z_index()

	if tutorial_panel: tutorial_panel.show()
	if dodge_panel: dodge_panel.hide()
	if attack_panel: attack_panel.hide()
	if engage_panel: engage_panel.hide()
	if observe_panel: observe_panel.hide()
	if suppress_panel: suppress_panel.hide()


	if PlayerRepository.current_enemy != null:
		enemy_resource = PlayerRepository.current_enemy

	assert(enemy_resource != null, "ERROR: Masukkan file .tres musuh di Inspector!")

	_setup_current_enemy()

	if enemy_sprite:
		default_enemy_pos = enemy_sprite.position

	_setup_button_labels()
	_setup_sub_action_buttons()
	_setup_main_buttons()
	if indication_arrow:
		indication_arrow.hide()

	if player_hp_bar:
		player_hp_bar.max_value = PlayerRepository.max_hp

	_update_ui_bars()
	_apply_enemy_button_restrictions()

	_switch_mode(BattleMode.DIALOGUE)
	_handle_start_battle()


func _setup_current_enemy() -> void:
	var e_name: String = enemy_resource.enemy_name.to_lower()
	is_tree_enemy = ("pohon" in e_name or "meranti" in e_name or "tree" in e_name)
	is_tree_enraged = ("mad" in e_name or "enraged" in e_name)
	observe_count = 0

	enemy_hp = enemy_resource.max_hp
	enemy_trust = 0
	enemy_stability = 0
	enemy_agitation = 0

	if "dialogue_resource" in enemy_resource and enemy_resource.get("dialogue_resource") != null:
		dialogue_resource = enemy_resource.get("dialogue_resource")

	_update_enemy_sprite_animation()
	_update_enemy_stats_card()


func _update_enemy_stats_card() -> void:
	if not enemy_stats or not enemy_resource:
		return

	var cards_node: TextureRect = enemy_cards_rect if enemy_cards_rect else enemy_stats.get_node_or_null("EnemyCards")
	var icon_node: TextureRect = enemy_icon_rect if enemy_icon_rect else enemy_stats.find_child("EnemyIcon", true, false)
	var name_node: Label = enemy_name_label if enemy_name_label else enemy_stats.find_child("EnemyName", true, false)

	if not cards_node:
		cards_node = TextureRect.new()
		cards_node.name = "EnemyCards"
		cards_node.offset_left = 24.0
		cards_node.offset_top = 135.0
		cards_node.offset_right = 418.0
		cards_node.offset_bottom = 515.0
		cards_node.texture = preload("res://assets/layer1cards.png")
		enemy_stats.add_child(cards_node)
		enemy_cards_rect = cards_node

	if not icon_node:
		icon_node = TextureRect.new()
		icon_node.name = "EnemyIcon"
		icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_node.offset_left = 44.0
		icon_node.offset_top = -12.0
		icon_node.offset_right = 244.0
		icon_node.offset_bottom = 188.0
		icon_node.scale = Vector2(1.5, 1.5)
		icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemy_stats.add_child(icon_node)
		enemy_icon_rect = icon_node

	if not name_node:
		name_node = Label.new()
		name_node.name = "EnemyName"
		name_node.offset_left = 6.0
		name_node.offset_top = 108.0
		name_node.offset_right = 503.0
		name_node.offset_bottom = 178.0
		name_node.rotation = -0.15707964
		name_node.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_node.add_theme_constant_override("outline_size", 12)
		name_node.add_theme_font_size_override("font_size", 70)
		var custom_font: Font = load("res://assets/fonts/raybees/Raybees-Regular.otf")
		if custom_font:
			name_node.add_theme_font_override("font", custom_font)
		cards_node.add_child(name_node)
		enemy_name_label = name_node

	if name_node.get_parent() != cards_node and cards_node.is_ancestor_of(name_node) == false:
		name_node.reparent(cards_node)
		name_node.offset_left = 6.0
		name_node.offset_top = 108.0
		name_node.offset_right = 503.0
		name_node.offset_bottom = 178.0
		name_node.rotation = -0.15707964

	if enemy_hp_bar and enemy_hp_bar.get_parent() != cards_node:
		enemy_hp_bar.reparent(cards_node)
		enemy_hp_bar.offset_left = 198.0
		enemy_hp_bar.offset_top = 141.0
		enemy_hp_bar.offset_right = 313.0
		enemy_hp_bar.offset_bottom = 208.0

	if enemy_agt_bar and enemy_agt_bar.get_parent() != cards_node:
		enemy_agt_bar.reparent(cards_node)
		enemy_agt_bar.offset_left = 211.0
		enemy_agt_bar.offset_top = 192.0
		enemy_agt_bar.offset_right = 351.0
		enemy_agt_bar.offset_bottom = 275.0

	var icon: Texture2D = null
	if "enemy_icon" in enemy_resource and enemy_resource.enemy_icon:
		icon = enemy_resource.enemy_icon
	else:
		icon = _get_fallback_enemy_icon()

	if icon_node:
		icon_node.texture = icon
		icon_node.visible = (icon != null)

	if name_node:
		var display_text: String = ""
		if enemy_resource.has_method("get_display_name"):
			display_text = enemy_resource.get_display_name()
		elif "display_name" in enemy_resource and not enemy_resource.display_name.is_empty():
			display_text = enemy_resource.display_name
		else:
			display_text = enemy_resource.enemy_name.replace("_", " ").to_upper()
		name_node.text = display_text
		name_node.show()


func _get_fallback_enemy_icon() -> Texture2D:
	if not enemy_resource:
		return null
	var n: String = enemy_resource.enemy_name.to_lower()
	if "meranti" in n or "tree" in n:
		if is_tree_enraged:
			return preload("res://assets/sprites/meranti_mad_icon.png")
		return preload("res://assets/sprites/meranti_icon.png")
	elif "ular" in n or "snake" in n or "enggano" in n:
		return preload("res://assets/sprites/ular_icon.png")
	elif "rafflesia" in n or "arnoldos" in n or "arnoldios" in n:
		return preload("res://assets/ui/maphutan/RafflesiaRendered.png")
	return null


func _update_enemy_sprite_animation() -> void:
	if not enemy_sprite or not enemy_sprite.sprite_frames:
		return

	var e_name: String = enemy_resource.enemy_name.to_lower()
	var target_anim: String = ""

	if "arnoldos" in e_name or "rafflesia" in e_name:
		target_anim = "arnoldos"
	elif "pohon" in e_name or "meranti" in e_name or "tree" in e_name:
		target_anim = "meranti_mad_tree" if is_tree_enraged else "meranti_tree"
	elif "ular" in e_name or "enggano" in e_name or "snake" in e_name:
		target_anim = "enggano_snake"
	else:
		target_anim = enemy_resource.enemy_name

	if enemy_sprite.sprite_frames.has_animation(target_anim):
		enemy_sprite.play(target_anim)
	else:
		push_warning("Animasi '%s' tidak ditemukan di SpriteFrames!" % target_anim)


func _clean_char_name(value: String) -> String:
	var s := value.to_lower().replace(" ", "").replace("_", "").replace("-", "").replace("'", "").replace("’", "")
	if s == "chicha":
		return "chika"
	return s

func _get_character_category(character_name: String, tags: PackedStringArray = []) -> CharacterCategory:
	for tag in tags:
		var t := tag.to_lower()
		if t in ["flora", "tumbuhan", "tanaman"]:
			return CharacterCategory.FLORA
		elif t in ["beast", "satwa", "hewan"]:
			return CharacterCategory.BEAST
		elif t in ["human", "manusia"]:
			return CharacterCategory.HUMAN

	var clean := _clean_char_name(character_name)
	for key in CHAR_CATEGORIES:
		if _clean_char_name(key) == clean:
			return CHAR_CATEGORIES[key]

	return CharacterCategory.HUMAN

func _update_battle_dialogue_box_texture(character_name: String, tags: PackedStringArray = []) -> void:
	if not slanted_dialogue_box or not (slanted_dialogue_box is TextureRect):
		return
	var category := _get_character_category(character_name, tags)
	match category:
		CharacterCategory.BEAST:
			if battle_texture_beast:
				slanted_dialogue_box.texture = battle_texture_beast
		CharacterCategory.FLORA:
			if battle_texture_flora:
				slanted_dialogue_box.texture = battle_texture_flora
		_:
			if battle_texture_human:
				slanted_dialogue_box.texture = battle_texture_human

func _fetch_dialogue(title: String, override_delay: float = -1.0) -> void:
	if not dialogue_resource:
		return

	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue_resource, title)

	while line != null:
		var current_speaker: String = line.character if not line.character.is_empty() else "DONGA"
		if speaker_name:
			speaker_name.text = current_speaker
		if log_text:
			log_text.text = line.text
		_update_battle_dialogue_box_texture(current_speaker, line.tags)

		var delay: float = default_dialogue_delay
		if override_delay > 0.0:
			delay = override_delay
		elif line.time != null and float(line.time) > 0.0:
			delay = float(line.time)

		await get_tree().create_timer(delay).timeout
		line = await DialogueManager.get_next_dialogue_line(dialogue_resource, line.next_id)


func _switch_mode(target_mode: BattleMode) -> void:
	current_mode = target_mode

	var current_focus := get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus()
	if current_mode != BattleMode.ACTION:
		_reset_main_buttons_z_index()
		if suppress_panel:
			suppress_panel.hide()

	mode_action.visible = (current_mode == BattleMode.ACTION)
	mode_dialogue.visible = (current_mode == BattleMode.DIALOGUE)
	mode_minigame.visible = (current_mode == BattleMode.MINIGAME)

	mode_action.set_process_input(current_mode == BattleMode.ACTION)
	mode_minigame.set_process_input(current_mode == BattleMode.MINIGAME)

	_animate_mode_transition(current_mode)


func change_state(new_state: BattleState) -> void:
	current_state = new_state
	match current_state:
		BattleState.START_BATTLE: _handle_start_battle()
		BattleState.PLAYER_TURN: _handle_player_turn()
		BattleState.ENEMY_TURN: _handle_enemy_turn()
		BattleState.END_BATTLE: _handle_end_battle()


func _setup_button_labels() -> void:
	if not suppress_box:
		return
	var btn_strike := suppress_box.get_node_or_null("BtnStrike/Label")
	if btn_strike: btn_strike.text = "* " + enemy_resource.suppress_1_name
	var btn_heavy := suppress_box.get_node_or_null("BtnHeavyStrike/Label")
	if btn_heavy: btn_heavy.text = "* " + enemy_resource.suppress_2_name


func _animate_mode_transition(mode: BattleMode) -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(anim_transition).set_ease(anim_ease)

	if mode != BattleMode.MINIGAME and is_instance_valid(enemy_sprite_clone):
		var old_clone := enemy_sprite_clone
		enemy_sprite_clone = null

		var target_return_pos := default_enemy_pos
		if mode == BattleMode.DIALOGUE:
			target_return_pos += enemy_dialogue_offset

		var cleanup_tween := create_tween().set_parallel(true)
		cleanup_tween.set_trans(anim_transition).set_ease(anim_ease)

		cleanup_tween.tween_property(old_clone, "position", target_return_pos, anim_duration)
		cleanup_tween.tween_property(old_clone, "modulate:a", 0.0, anim_duration)
		cleanup_tween.chain().tween_callback(old_clone.queue_free)

	if mode == BattleMode.DIALOGUE:
		if enemy_sprite:
			tween.tween_property(enemy_sprite, "position", default_enemy_pos + enemy_dialogue_offset, anim_duration)

		if floating_bar:
			tween.tween_property(floating_bar, "modulate:a", 0.0, anim_duration * 0.6)
			tween.chain().tween_callback(floating_bar.hide)

		if slanted_dialogue_box:
			slanted_dialogue_box.pivot_offset = slanted_dialogue_box.size / 2.0
			slanted_dialogue_box.scale = Vector2(0.8, 0.8)
			slanted_dialogue_box.modulate.a = 0.0

			var box_tween := create_tween().set_parallel(true)
			box_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			box_tween.tween_property(slanted_dialogue_box, "scale", Vector2.ONE, anim_duration)
			box_tween.tween_property(slanted_dialogue_box, "modulate:a", 1.0, anim_duration * 0.7)

	elif mode == BattleMode.ACTION:
		if enemy_sprite:
			tween.tween_property(enemy_sprite, "position", default_enemy_pos, anim_duration)

		if floating_bar:
			floating_bar.show()
			tween.tween_property(floating_bar, "modulate:a", 1.0, anim_duration)

		_animate_pop_in(mode_action)

	elif mode == BattleMode.MINIGAME:
		var target_orig_pos := default_enemy_pos + enemy_minigame_offset
		var target_clone_offset := Vector2(-enemy_minigame_offset.x, enemy_minigame_offset.y)
		var target_clone_pos := default_enemy_pos + target_clone_offset

		if enemy_sprite:
			tween.tween_property(enemy_sprite, "position", target_orig_pos, anim_duration)

		if enemy_sprite and not is_instance_valid(enemy_sprite_clone):
			enemy_sprite_clone = enemy_sprite.duplicate() as AnimatedSprite2D
			enemy_sprite.add_sibling(enemy_sprite_clone)
			enemy_sprite_clone.position = enemy_sprite.position
			enemy_sprite_clone.modulate.a = 0.0

			if enemy_sprite.sprite_frames and enemy_sprite.animation:
				enemy_sprite_clone.play(enemy_sprite.animation)

		if is_instance_valid(enemy_sprite_clone):
			tween.tween_property(enemy_sprite_clone, "position", target_clone_pos, anim_duration)
			tween.tween_property(enemy_sprite_clone, "modulate:a", 1.0, anim_duration)

		if floating_bar:
			tween.tween_property(floating_bar, "modulate:a", 0.0, anim_duration * 0.6)
			tween.chain().tween_callback(floating_bar.hide)

		if enemy_attack_container:
			_animate_pop_in(enemy_attack_container)


func _animate_pop_in(target: Control) -> void:
	if not target:
		return
	target.pivot_offset = target.size / 2.0
	target.scale = Vector2(0.7, 0.7)
	target.modulate.a = 0.0
	target.show()

	var tween := create_tween().set_parallel(true)
	tween.set_trans(anim_transition).set_ease(anim_ease)
	tween.tween_property(target, "scale", Vector2.ONE, anim_duration)
	tween.tween_property(target, "modulate:a", 1.0, anim_duration * 0.8)


func _animate_pop_out(target: Control, hide_on_finish: bool = true) -> void:
	if not target or not target.visible:
		return
	target.pivot_offset = target.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", Vector2(0.8, 0.8), anim_duration * 0.7)
	tween.tween_property(target, "modulate:a", 0.0, anim_duration * 0.7)

	if hide_on_finish:
		tween.chain().tween_callback(target.hide)


func _handle_start_battle() -> void:
	_switch_mode(BattleMode.DIALOGUE)
	await _fetch_dialogue("intro")
	change_state(BattleState.PLAYER_TURN)


func _handle_player_turn() -> void:
	_switch_mode(BattleMode.ACTION)
	sub_action_panel.visible = false
	if indication_arrow:
		indication_arrow.hide()
	_reset_sub_action_buttons_scale()
	_reset_main_buttons_z_index()

	var main_container := $Mode_Action/MainButtonContainer
	var btn_suppress: BaseButton = main_container.get_node_or_null("BtnSuppress")
	var btn_observe: BaseButton = main_container.get_node_or_null("BtnObserve")
	var btn_engage: BaseButton = main_container.get_node_or_null("BtnEngage")

	if _is_rafflesia_enemy() and is_first_suppress_tutorial:
		is_first_suppress_tutorial = false
		if suppress_panel: suppress_panel.show()
		if observe_panel: observe_panel.hide()
		if engage_panel: engage_panel.hide()
		var buttons := _get_main_buttons()
		var idx := buttons.find(btn_suppress)
		_select_main_button(idx if idx != -1 else 0, true)
		return

	if is_tree_enemy and is_tree_enraged and is_first_mad_tree_observe_hint:
		is_first_mad_tree_observe_hint = false
		if suppress_panel: suppress_panel.hide()
		if observe_panel: observe_panel.show()
		if engage_panel: engage_panel.hide()
		var buttons := _get_main_buttons()
		var idx := buttons.find(btn_observe)
		_select_main_button(idx if idx != -1 else 0, true)
		return

	if is_tree_enemy and is_tree_enraged and is_first_mad_tree_engage_hint:
		is_first_mad_tree_engage_hint = false
		if suppress_panel: suppress_panel.hide()
		if observe_panel: observe_panel.hide()
		if engage_panel: engage_panel.show()
		var buttons := _get_main_buttons()
		var idx := buttons.find(btn_engage)
		_select_main_button(idx if idx != -1 else 0, true)
		return

	if suppress_panel: suppress_panel.hide()
	if observe_panel: observe_panel.hide()
	if engage_panel: engage_panel.hide()
	_select_main_button(_main_button_index, true)


func _handle_enemy_turn() -> void:
	_switch_mode(BattleMode.DIALOGUE)

	if is_tree_enemy and is_tree_enraged:
		await _fetch_dialogue("tree_angry_turn")
	else:
		await _fetch_dialogue("enemy_turn")

	_switch_mode(BattleMode.MINIGAME)
	player_attack_game.visible = false
	enemy_attack_container.visible = true
	arena_decoration.visible = true

	var is_dodge_tut: bool = _is_rafflesia_enemy() and is_first_dodge_tutorial
	if is_dodge_tut:
		is_first_dodge_tutorial = false
		if dodge_panel:
			dodge_panel.show()

	enemy_attack_game.start_phase(enemy_resource, enemy_agitation)
	var total_hits: int = await enemy_attack_game.minigame_finished

	if is_dodge_tut and dodge_panel:
		dodge_panel.hide()

	_switch_mode(BattleMode.DIALOGUE)
	_resolve_enemy_damage(total_hits)


func _handle_end_battle() -> void:
	_switch_mode(BattleMode.DIALOGUE)

	if enemy_hp <= 0:
		await _fetch_dialogue("defeat_by_hp")
	elif enemy_trust >= 100:
		await _fetch_dialogue("defeat_by_trust")
	elif enemy_stability >= 100:
		await _fetch_dialogue("defeat_by_stability")
	else:
		await _fetch_dialogue("battle_finished_default")

	var e_name: String = enemy_resource.enemy_name.to_lower()

	print("--- DEBUG END BATTLE ---")
	print("Nama Musuh: ", e_name)
	print("is_tree_enemy: ", is_tree_enemy)

	if is_tree_enemy:
		_transition_to_snake_battle()
	elif "ular" in e_name or "enggano" in e_name or "snake" in e_name:
		_transition_to_snake_cleared_map()
	elif "arnoldos" in e_name or "rafflesia" in e_name:
		_transition_to_house_cutscene()
	else:
		_return_to_map()

func _transition_to_snake_battle() -> void:
	if not snake_enemy_resource:
		snake_enemy_resource = load("res://data/enemies/ular_enggano.tres")

	if snake_enemy_resource:
		enemy_resource = snake_enemy_resource
		PlayerRepository.current_enemy = snake_enemy_resource

		_setup_current_enemy()
		_setup_button_labels()
		_update_ui_bars()
		_apply_enemy_button_restrictions()

		change_state(BattleState.START_BATTLE)
	else:
		push_warning("snake_enemy_resource tidak ditemukan, kembali ke map.")
		_return_to_map()


func _transition_to_snake_cleared_map() -> void:
	PlayerRepository.is_snake_cleared = true
	_return_to_map()

func _transition_to_house_cutscene() -> void:
	var transition_anim: AnimationPlayer = $AnimationPlayer
	if transition_anim and transition_anim.has_animation("end_rafflesia"):
		transition_anim.play("end_rafflesia")
		await transition_anim.animation_finished

	PlayerRepository.should_restore_position = false
	PlayerRepository.end_battle(true)

	SceneTransition.change_scene("res://game/world/rumah_donga/rumah_donga.tscn")


func _return_to_map() -> void:
	PlayerRepository.end_battle(true)
	PlayerRepository.should_restore_position = true

	var transition_anim: AnimationPlayer = $AnimationPlayer
	if transition_anim != null and transition_anim.has_animation("circle_out"):
		transition_anim.play("circle_out")
		await transition_anim.animation_finished

	get_tree().change_scene_to_file(PlayerRepository.last_map_path)


func _on_btn_strike_pressed() -> void:
	_execute_attack_minigame(1.0, 1.0, enemy_resource.suppress_1_hp, enemy_resource.suppress_1_agit, "suppress_1")


func _on_btn_heavy_strike_pressed() -> void:
	_execute_attack_minigame(1.6, 1.8, enemy_resource.suppress_2_hp, enemy_resource.suppress_2_agit, "suppress_2")



func _execute_attack_minigame(speed_mod: float, damage_scale: float, base_hp: int, base_agit: int, dialogue_tag: String) -> void:
	_hide_sub_action_panel()
	_switch_mode(BattleMode.MINIGAME)
	enemy_attack_container.visible = false
	player_attack_game.visible = true
	arena_decoration.visible = false

	if _is_rafflesia_enemy() and is_first_attack_tutorial:
		is_first_attack_tutorial = false

		await _play_attack_tutorial_sequence()

		_switch_mode(BattleMode.DIALOGUE)
		enemy_hp = clampi(enemy_hp - 10, 0, 100)
		enemy_agitation = clampi(enemy_agitation + base_agit, 0, 100)
		await _fetch_dialogue(dialogue_tag)
		_finalize_player_action()
		return

	player_attack_game.start_phase(speed_mod)
	var accuracy_score: float = await player_attack_game.minigame_finished

	_switch_mode(BattleMode.DIALOGUE)
	_resolve_player_attack(accuracy_score, damage_scale, base_hp, base_agit, dialogue_tag)


func _resolve_player_attack(score: float, damage_scale: float, base_hp: int, base_agit: int, dialogue_tag: String) -> void:
	if score > 0.0:
		var raw_damage := absf(float(base_hp)) * damage_scale

		if is_tree_enemy and is_tree_enraged:
			raw_damage *= 0.3

		var calculated_damage := roundi(raw_damage * score)
		enemy_hp = clampi(enemy_hp - calculated_damage, 0, 100)

		var calculated_agit := roundi(absf(float(base_agit)) * score)
		enemy_agitation = clampi(enemy_agitation + calculated_agit, 0, 100)

		await _fetch_dialogue(dialogue_tag)
	else:
		await _fetch_dialogue("attack_miss")

	_finalize_player_action()


func _finalize_player_action() -> void:
	_update_ui_bars()

	if is_tree_enemy and not is_tree_enraged and enemy_hp <= 0:
		await _trigger_tree_enrage()
		change_state(BattleState.ENEMY_TURN)
		return
	if _check_victory_conditions():
		change_state(BattleState.END_BATTLE)
	else:
		change_state(BattleState.ENEMY_TURN)


func _trigger_tree_enrage() -> void:
	is_tree_enraged = true
	observe_count = 0
	is_first_mad_tree_observe_hint = true
	is_first_mad_tree_engage_hint = false

	_switch_mode(BattleMode.DIALOGUE)

	if not tree_mad_enemy_resource:
		tree_mad_enemy_resource = load("res://data/enemies/meranti_enraged.tres")

	if tree_mad_enemy_resource:
		enemy_resource = tree_mad_enemy_resource
		PlayerRepository.current_enemy = tree_mad_enemy_resource

		enemy_hp = enemy_resource.max_hp
		enemy_agitation = 100

		_update_enemy_sprite_animation()
		_setup_button_labels()
		_update_ui_bars()
		_apply_enemy_button_restrictions()
	else:
		push_warning("tree_mad_enemy_resource tidak ditemukan!")

	await _fetch_dialogue("tree_enrage_intro")


func _resolve_enemy_damage(total_hits: int) -> void:
	var final_damage := 0

	if total_hits > 0:
		var base_damage := float(enemy_resource.base_damage)
		if enemy_agitation >= 50:
			base_damage = float(enemy_resource.rage_damage)

		final_damage = roundi(base_damage * total_hits)
		await _fetch_dialogue("enemy_damage_hit")
	else:
		await _fetch_dialogue("enemy_damage_dodge")

	PlayerRepository.take_damage(final_damage)
	enemy_agitation = clampi(enemy_agitation + 10, 0, 100)
	_update_ui_bars()

	if _check_victory_conditions():
		change_state(BattleState.END_BATTLE)
	else:
		change_state(BattleState.PLAYER_TURN)


func _hide_all_sub_action_boxes() -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	if indication_arrow:
		indication_arrow.hide()
	_reset_sub_action_buttons_scale()
	_reset_main_buttons_z_index()
	suppress_box.visible = false
	observe_box.visible = false
	engage_box.visible = false
	adapt_box.visible = false
	var item_box: Control = sub_action_panel.get_node_or_null("ItemBox")
	if item_box:
		item_box.visible = false


func _on_btn_suppress_pressed() -> void:
	if suppress_panel:
		suppress_panel.hide()
	_reset_main_buttons_z_index()

	_hide_all_sub_action_boxes()
	suppress_box.scale = Vector2.ONE
	suppress_box.modulate.a = 1.0
	suppress_box.visible = true
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_select_sub_action_button(0, true)


func _on_btn_observe_pressed() -> void:
	if suppress_panel:
		suppress_panel.hide()
	if observe_panel:
		observe_panel.hide()
	_reset_main_buttons_z_index()

	_hide_all_sub_action_boxes()
	observe_box.scale = Vector2.ONE
	observe_box.modulate.a = 1.0
	observe_box.visible = true
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_select_sub_action_button(0, true)


func _on_btn_engage_pressed() -> void:
	if suppress_panel:
		suppress_panel.hide()
	var required_observe: int = 1 if (is_tree_enemy and is_tree_enraged) else 3
	if observe_count < required_observe:
		_switch_mode(BattleMode.DIALOGUE)
		await _fetch_dialogue("observe_insufficient")
		_switch_mode(BattleMode.ACTION)
		return

	if engage_panel:
		engage_panel.hide()
	_reset_main_buttons_z_index()

	_hide_all_sub_action_boxes()
	engage_box.scale = Vector2.ONE
	engage_box.modulate.a = 1.0
	engage_box.visible = true
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_select_sub_action_button(0, true)


func _on_btn_adapt_pressed() -> void:
	if suppress_panel:
		suppress_panel.hide()
	_hide_all_sub_action_boxes()
	adapt_box.scale = Vector2.ONE
	adapt_box.modulate.a = 1.0
	adapt_box.visible = true
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_select_sub_action_button(0, true)


func _on_sub_action_back_pressed() -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	if indication_arrow:
		indication_arrow.hide()
	_reset_sub_action_buttons_scale()
	sub_action_panel.scale = Vector2.ONE
	sub_action_panel.modulate.a = 1.0
	sub_action_panel.visible = false
	_select_main_button(_main_button_index, false)


func _update_ui_bars() -> void:
	if player_hp_bar:
		player_hp_bar.value = PlayerRepository.hp
	if player_str_bar:
		player_str_bar.value = PlayerRepository.str

	if enemy_hp_bar:
		enemy_hp_bar.value = enemy_hp
	if enemy_agt_bar:
		enemy_agt_bar.value = enemy_agitation

	if trust_bar:
		trust_bar.value = enemy_trust
	if stability_bar:
		stability_bar.value = enemy_stability


func _check_victory_conditions() -> bool:
	if PlayerRepository.hp <= 0:
		return true

	if is_tree_enemy and not is_tree_enraged:
		return enemy_trust >= 100 or enemy_stability >= 100

	return enemy_hp <= 0 or enemy_trust >= 100 or enemy_stability >= 100


func _on_btn_item_pressed() -> void:
	if suppress_panel:
		suppress_panel.hide()
	_hide_all_sub_action_boxes()
	var item_box: Control = sub_action_panel.get_node_or_null("ItemBox")
	if item_box:
		item_box.scale = Vector2.ONE
		item_box.modulate.a = 1.0
		item_box.visible = true
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_select_sub_action_button(0, true)


func _on_btn_species_pressed() -> void:
	var trust_gain: int = enemy_resource.observe_species_trust if "observe_species_trust" in enemy_resource else 10
	_resolve_observe("observe_species", trust_gain)


func _on_btn_status_pressed() -> void:
	var trust_gain: int = enemy_resource.observe_status_trust if "observe_status_trust" in enemy_resource else 10
	_resolve_observe("observe_status", trust_gain)


func _on_btn_cause_pressed() -> void:
	var trust_gain: int = enemy_resource.observe_cause_trust if "observe_cause_trust" in enemy_resource else 15
	_resolve_observe("observe_cause", trust_gain)


func _resolve_observe(dialogue_tag: String, trust_gain: int) -> void:
	if observe_panel:
		observe_panel.hide()
	_reset_main_buttons_z_index()

	_hide_sub_action_panel()
	_switch_mode(BattleMode.DIALOGUE)

	observe_count += 1
	enemy_trust = clampi(enemy_trust + trust_gain, 0, 100)
	_update_ui_bars()

	await _fetch_dialogue(dialogue_tag)

	var required_observe: int = 1 if (is_tree_enemy and is_tree_enraged) else 3

	if observe_count >= required_observe:
		if enemy_resource and enemy_resource.enemy_name != "Rafflesia":
			var btn_engage: BaseButton = $Mode_Action/MainButtonContainer.get_node_or_null("BtnEngage")
			if btn_engage:
				btn_engage.disabled = false
				btn_engage.modulate = Color(1.0, 1.0, 1.0, 1.0)

		if is_tree_enemy and is_tree_enraged:
			is_first_mad_tree_engage_hint = true

		await _fetch_dialogue("observe_unlocked_info")

	_finalize_player_action()


func _on_btn_choice_a_pressed() -> void:
	var is_correct: bool = enemy_resource.choice_a_is_correct if "choice_a_is_correct" in enemy_resource else true
	var trust_val: int = enemy_resource.choice_a_trust if "choice_a_trust" in enemy_resource else 25
	_resolve_engage("engage_choice_a", is_correct, trust_val)


func _on_btn_choice_b_pressed() -> void:
	var is_correct: bool = enemy_resource.choice_b_is_correct if "choice_b_is_correct" in enemy_resource else false
	var trust_val: int = enemy_resource.choice_b_trust if "choice_b_trust" in enemy_resource else 15
	_resolve_engage("engage_choice_b", is_correct, trust_val)


func _on_btn_choice_c_pressed() -> void:
	var is_correct: bool = enemy_resource.choice_c_is_correct if "choice_c_is_correct" in enemy_resource else true
	var trust_val: int = enemy_resource.choice_c_trust if "choice_c_trust" in enemy_resource else 20
	_resolve_engage("engage_choice_c", is_correct, trust_val)


func _on_btn_choice_d_pressed() -> void:
	var is_correct: bool = enemy_resource.choice_d_is_correct if "choice_d_is_correct" in enemy_resource else false
	var trust_val: int = enemy_resource.choice_d_trust if "choice_d_trust" in enemy_resource else 15
	_resolve_engage("engage_choice_d", is_correct, trust_val)


func _resolve_engage(dialogue_tag: String, is_correct: bool, trust_change: int) -> void:
	_hide_sub_action_panel()
	_switch_mode(BattleMode.DIALOGUE)

	if is_correct:
		var final_trust_gain := trust_change
		if is_tree_enemy and is_tree_enraged:
			final_trust_gain = roundi(trust_change * 1.5)

		enemy_trust = clampi(enemy_trust + final_trust_gain, 0, 100)
	else:
		enemy_trust = clampi(enemy_trust - trust_change, 0, 100)
		enemy_agitation = clampi(enemy_agitation + 15, 0, 100)

	_update_ui_bars()
	await _fetch_dialogue(dialogue_tag)
	_finalize_player_action()


func _on_btn_water_pressed() -> void:
	var stab: int = enemy_resource.adapt_water_stability if "adapt_water_stability" in enemy_resource else 25
	var trust: int = enemy_resource.adapt_water_trust if "adapt_water_trust" in enemy_resource else 10
	_resolve_adapt("adapt_water", stab, trust)


func _on_btn_plant_pressed() -> void:
	var stab: int = enemy_resource.adapt_plant_stability if "adapt_plant_stability" in enemy_resource else 35
	var trust: int = enemy_resource.adapt_plant_trust if "adapt_plant_trust" in enemy_resource else 15
	_resolve_adapt("adapt_plant", stab, trust)


func _on_btn_path_pressed() -> void:
	var stab: int = enemy_resource.adapt_path_stability if "adapt_path_stability" in enemy_resource else 20
	var trust: int = enemy_resource.adapt_path_trust if "adapt_path_trust" in enemy_resource else 10
	_resolve_adapt("adapt_path", stab, trust)


func _on_btn_trap_pressed() -> void:
	var stab: int = enemy_resource.adapt_trap_stability if "adapt_trap_stability" in enemy_resource else 20
	var trust: int = enemy_resource.adapt_trap_trust if "adapt_trap_trust" in enemy_resource else 20
	_resolve_adapt("adapt_trap", stab, trust)


func _resolve_adapt(dialogue_tag: String, stability_gain: int, trust_gain: int) -> void:
	_hide_sub_action_panel()
	_switch_mode(BattleMode.DIALOGUE)

	enemy_stability = clampi(enemy_stability + stability_gain, 0, 100)
	enemy_trust = clampi(enemy_trust + trust_gain, 0, 100)
	_update_ui_bars()

	await _fetch_dialogue(dialogue_tag)
	_finalize_player_action()


func _on_btn_ramuan_akar_pressed() -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)

	var heal_amount: int = 30
	PlayerRepository.heal(heal_amount)

	await _fetch_dialogue("item_ramuan_akar")
	_finalize_player_action()


func _apply_enemy_button_restrictions() -> void:
	var main_container := $Mode_Action/MainButtonContainer
	var btn_observe: BaseButton = main_container.get_node_or_null("BtnObserve")
	var btn_engage: BaseButton = main_container.get_node_or_null("BtnEngage")
	var btn_adapt: BaseButton = main_container.get_node_or_null("BtnAdapt")
	var btn_item: BaseButton = main_container.get_node_or_null("BtnItem")

	if enemy_resource and enemy_resource.enemy_name == "Rafflesia":
		if btn_observe:
			btn_observe.disabled = true
			btn_observe.modulate = Color(0.5, 0.5, 0.5, 0.8)
		if btn_engage:
			btn_engage.disabled = true
			btn_engage.modulate = Color(0.5, 0.5, 0.5, 0.8)
		if btn_adapt:
			btn_adapt.disabled = true
			btn_adapt.modulate = Color(0.5, 0.5, 0.5, 0.8)
		if btn_item:
			btn_item.disabled = true
			btn_item.modulate = Color(0.5, 0.5, 0.5, 0.8)
	else:
		var required_observe: int = 1 if (is_tree_enemy and is_tree_enraged) else 3
		if btn_engage and observe_count < required_observe:
			btn_engage.disabled = true
			btn_engage.modulate = Color(0.5, 0.5, 0.5, 0.8)


func _is_rafflesia_enemy() -> bool:
	if not enemy_resource:
		return false
	var e_name: String = enemy_resource.enemy_name.to_lower()
	return "arnoldos" in e_name or "arnoldios" in e_name or "rafflesia" in e_name


func _play_attack_tutorial() -> void:
	var anim_player: AnimationPlayer = $AnimationPlayer
	if anim_player and anim_player.has_animation("tutorial_attack"):
		anim_player.play("tutorial_attack")

	while true:
		await get_tree().process_frame
		if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			break

	if anim_player and anim_player.is_playing():
		anim_player.stop()


func _show_dodge_tutorial_hint() -> void:
	var hint_label: Label = mode_minigame.get_node_or_null("DodgeHint")
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "DodgeHint"
		hint_label.text = "Hindari serangan dengan tombol WASD!"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		hint_label.position.y += 24.0
		mode_minigame.add_child(hint_label)

	hint_label.modulate.a = 0.0
	hint_label.show()

	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(hint_label.hide)


func _play_attack_tutorial_sequence() -> void:
	if attack_panel:
		attack_panel.hide()

	var anim_player: AnimationPlayer = null
	if is_instance_valid(player_attack_game) and player_attack_game.has_node("TutorialAnimation"):
		anim_player = player_attack_game.get_node("TutorialAnimation")
	elif has_node("TutorialAnimation"):
		anim_player = $TutorialAnimation
	elif has_node("AnimationPlayer"):
		anim_player = $AnimationPlayer

	if anim_player and anim_player.has_animation("tutorial_attack"):
		anim_player.play("tutorial_attack")
		await anim_player.animation_finished

	if attack_panel:
		attack_panel.show()

	while true:
		await get_tree().process_frame
		if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			break

	if attack_panel:
		attack_panel.hide()

	if anim_player and anim_player.is_playing():
		anim_player.stop()


func _reset_main_buttons_z_index() -> void:
	var container = get_node_or_null("Mode_Action/MainButtonContainer")
	if container:
		for child in container.get_children():
			if child is CanvasItem:
				child.z_index = 0
			if child is Control:
				if child.has_meta("tween"):
					var old_tw: Tween = child.get_meta("tween")
					if old_tw and old_tw.is_valid():
						old_tw.kill()
				child.scale = Vector2.ONE
				if child.has_focus():
					child.release_focus()


func _setup_main_buttons() -> void:
	var container = get_node_or_null("Mode_Action/MainButtonContainer")
	if not container:
		return
	for child in container.get_children():
		if child is TextureButton:
			child.focus_mode = Control.FOCUS_ALL
			child.focus_neighbor_left = child.get_path()
			child.focus_neighbor_right = child.get_path()
			child.focus_neighbor_top = child.get_path()
			child.focus_neighbor_bottom = child.get_path()
			child.texture_hover = null
			child.texture_focused = null
			if not child.mouse_entered.is_connected(_on_main_button_hovered.bind(child)):
				child.mouse_entered.connect(_on_main_button_hovered.bind(child))


func _on_main_button_hovered(btn: TextureButton) -> void:
	if current_mode != BattleMode.ACTION or (sub_action_panel and sub_action_panel.visible):
		return
	if btn.is_disabled():
		return
	var buttons := _get_main_buttons()
	var idx := buttons.find(btn)
	if idx != -1 and idx != _main_button_index:
		_main_button_index = idx
		_update_main_button_selection(false)


func _get_main_buttons() -> Array[TextureButton]:
	var container = get_node_or_null("Mode_Action/MainButtonContainer")
	if not container or not container.visible:
		return []
	var buttons: Array[TextureButton] = []
	for child in container.get_children():
		if child is TextureButton and child.visible and not child.is_disabled():
			buttons.append(child)
	return buttons


func _select_main_button(index: int, instant: bool = false) -> void:
	var buttons := _get_main_buttons()
	if buttons.is_empty():
		return
	_main_button_index = clampi(index, 0, buttons.size() - 1)
	_update_main_button_selection(instant)


func _update_main_button_selection(instant: bool = false) -> void:
	var buttons := _get_main_buttons()
	if buttons.is_empty():
		return

	if _main_button_index >= buttons.size():
		_main_button_index = 0

	for i in range(buttons.size()):
		var btn := buttons[i]
		var btn_sz: Vector2 = btn.size
		if btn_sz == Vector2.ZERO and btn.texture_normal:
			btn_sz = btn.texture_normal.get_size()
		btn.pivot_offset = btn_sz / 2.0
		if btn.has_meta("tween"):
			var old_tw: Tween = btn.get_meta("tween")
			if old_tw and old_tw.is_valid():
				old_tw.kill()
		if i == _main_button_index:
			btn.z_index = 10
			btn.grab_focus()
			if instant:
				btn.scale = Vector2(1.1, 1.1)
			else:
				var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
				btn.set_meta("tween", tw)
		else:
			btn.z_index = 0
			if btn.has_focus():
				btn.release_focus()
			if instant:
				btn.scale = Vector2.ONE
			else:
				var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
				btn.set_meta("tween", tw)


func _navigate_main_button(direction: int) -> void:
	var buttons := _get_main_buttons()
	if buttons.is_empty():
		return
	_main_button_index = posmod(_main_button_index + direction, buttons.size())
	_update_main_button_selection(false)


func _navigate_main_button_vertical(direction: int) -> void:
	var buttons := _get_main_buttons()
	if buttons.is_empty():
		return
	var container = get_node_or_null("Mode_Action/MainButtonContainer")
	if not container:
		return
	var item_btn: TextureButton = container.get_node_or_null("BtnItem")
	var item_idx := buttons.find(item_btn)
	if direction < 0:
		if item_idx != -1 and _main_button_index != item_idx:
			_select_main_button(item_idx, false)
	else:
		if item_idx != -1 and _main_button_index == item_idx:
			var engage_btn: TextureButton = container.get_node_or_null("BtnEngage")
			var engage_idx := buttons.find(engage_btn)
			if engage_idx != -1:
				_select_main_button(engage_idx, false)
			else:
				_select_main_button(0, false)


func _setup_sub_action_buttons() -> void:
	if not sub_action_panel:
		return
	var item_box: Control = sub_action_panel.get_node_or_null("ItemBox")
	var boxes: Array = [suppress_box, observe_box, engage_box, adapt_box, item_box]
	for box in boxes:
		if not box:
			continue
		for child in box.get_children():
			if child is TextureButton:
				child.focus_mode = Control.FOCUS_ALL
				child.focus_neighbor_left = child.get_path()
				child.focus_neighbor_right = child.get_path()
				child.focus_neighbor_top = child.get_path()
				child.focus_neighbor_bottom = child.get_path()
				child.texture_hover = null
				child.texture_focused = null
				if not child.mouse_entered.is_connected(_on_sub_action_button_hovered.bind(child)):
					child.mouse_entered.connect(_on_sub_action_button_hovered.bind(child))


func _on_sub_action_button_hovered(btn: TextureButton) -> void:
	if not sub_action_panel or not sub_action_panel.visible:
		return
	var buttons := _get_sub_action_buttons()
	var idx := buttons.find(btn)
	if idx != -1 and idx != _sub_action_index:
		_sub_action_index = idx
		_update_indication_arrow(false)


func _reset_sub_action_buttons_scale() -> void:
	if not sub_action_panel:
		return
	var item_box: Control = sub_action_panel.get_node_or_null("ItemBox")
	var boxes: Array = [suppress_box, observe_box, engage_box, adapt_box, item_box]
	for box in boxes:
		if not box:
			continue
		for child in box.get_children():
			if child is TextureButton:
				if child.has_meta("tween"):
					var old_tw: Tween = child.get_meta("tween")
					if old_tw and old_tw.is_valid():
						old_tw.kill()
				child.scale = Vector2.ONE
				child.z_index = 0
				if child.has_focus():
					child.release_focus()


func _hide_sub_action_panel() -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	if indication_arrow:
		indication_arrow.hide()
	_reset_sub_action_buttons_scale()
	sub_action_panel.hide()


func _get_active_sub_box() -> Control:
	if suppress_box and suppress_box.visible:
		return suppress_box
	if observe_box and observe_box.visible:
		return observe_box
	if engage_box and engage_box.visible:
		return engage_box
	if adapt_box and adapt_box.visible:
		return adapt_box
	var item_box: Control = sub_action_panel.get_node_or_null("ItemBox")
	if item_box and item_box.visible:
		return item_box
	return null


func _get_sub_action_buttons() -> Array[TextureButton]:
	var active_box := _get_active_sub_box()
	if not active_box:
		return []
	var buttons: Array[TextureButton] = []
	for child in active_box.get_children():
		if child is TextureButton and child.visible and not child.is_disabled():
			buttons.append(child)
	return buttons


func _get_button_visual_center_x(btn: TextureButton) -> float:
	match btn.name:
		"BtnStrike":
			return 92.0
		"BtnHeavyStrike":
			return 148.0
		"BtnSpecies":
			return 176.0
		"BtnStatus":
			return 128.0
		"BtnCause":
			return 144.0
		"BtnChoiceA":
			return 141.0
		"BtnChoiceB", "BtnChoiceC", "BtnChoiceD":
			return 134.0
		"BtnWater", "BtnTrap":
			return 92.0
		"BtnPlant":
			return 148.0
		"BtnPath":
			return 126.0
		_:
			if btn.size.x > 0:
				return btn.size.x / 2.0
			if btn.texture_normal:
				return btn.texture_normal.get_width() / 2.0
			return 0.0


func _select_sub_action_button(index: int, instant: bool = false) -> void:
	var buttons := _get_sub_action_buttons()
	if buttons.is_empty():
		if indication_arrow:
			indication_arrow.hide()
		return
	_sub_action_index = clampi(index, 0, buttons.size() - 1)
	if buttons[_sub_action_index].size.x <= 0:
		await get_tree().process_frame
	_update_indication_arrow(instant)


func _update_indication_arrow(instant: bool = false) -> void:
	var buttons := _get_sub_action_buttons()
	if buttons.is_empty() or not indication_arrow:
		if indication_arrow:
			indication_arrow.hide()
		return

	if _sub_action_index >= buttons.size():
		_sub_action_index = 0

	var target_button := buttons[_sub_action_index]
	var active_box := _get_active_sub_box()
	if not active_box:
		return

	for i in range(buttons.size()):
		var btn := buttons[i]
		var center_x := _get_button_visual_center_x(btn)
		var center_y := btn.size.y / 2.0 if btn.size.y > 0 else (btn.texture_normal.get_height() / 2.0 if btn.texture_normal else 0.0)
		btn.pivot_offset = Vector2(center_x, center_y)
		if btn.has_meta("tween"):
			var old_tw: Tween = btn.get_meta("tween")
			if old_tw and old_tw.is_valid():
				old_tw.kill()
		if i == _sub_action_index:
			btn.z_index = 2
			btn.grab_focus()
			if instant:
				btn.scale = Vector2(1.1, 1.1)
			else:
				var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
				btn.set_meta("tween", tw)
		else:
			btn.z_index = 0
			if btn.has_focus():
				btn.release_focus()
			if instant:
				btn.scale = Vector2.ONE
			else:
				var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
				btn.set_meta("tween", tw)

	indication_arrow.show()
	var button_center_x: float = active_box.position.x + target_button.position.x + _get_button_visual_center_x(target_button)
	var target_x: float = button_center_x - (indication_arrow.size.x / 2.0)

	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()

	if instant:
		indication_arrow.position.x = target_x
	else:
		_arrow_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_arrow_tween.tween_property(indication_arrow, "position:x", target_x, 0.08)


func _navigate_sub_action(direction: int) -> void:
	var buttons := _get_sub_action_buttons()
	if buttons.is_empty():
		return
	_sub_action_index = posmod(_sub_action_index + direction, buttons.size())
	_update_indication_arrow(false)


func _input(event: InputEvent) -> void:
	if current_mode != BattleMode.ACTION:
		return

	if sub_action_panel and sub_action_panel.visible:
		if event.is_action_pressed("ui_right") or event.is_action_pressed("walk_right") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_RIGHT or event.keycode == KEY_D)):
			get_viewport().set_input_as_handled()
			_navigate_sub_action(1)
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("walk_left") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_LEFT or event.keycode == KEY_A)):
			get_viewport().set_input_as_handled()
			_navigate_sub_action(-1)
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("esc") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_X)):
			get_viewport().set_input_as_handled()
			_on_sub_action_back_pressed()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_Z)):
			get_viewport().set_input_as_handled()
			var buttons := _get_sub_action_buttons()
			if not buttons.is_empty() and _sub_action_index >= 0 and _sub_action_index < buttons.size():
				buttons[_sub_action_index].pressed.emit()
	else:
		if event.is_action_pressed("ui_right") or event.is_action_pressed("walk_right") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_RIGHT or event.keycode == KEY_D)):
			get_viewport().set_input_as_handled()
			_navigate_main_button(1)
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("walk_left") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_LEFT or event.keycode == KEY_A)):
			get_viewport().set_input_as_handled()
			_navigate_main_button(-1)
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("walk_up") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_UP or event.keycode == KEY_W)):
			get_viewport().set_input_as_handled()
			_navigate_main_button_vertical(-1)
		elif event.is_action_pressed("ui_down") or event.is_action_pressed("walk_down") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_DOWN or event.keycode == KEY_S)):
			get_viewport().set_input_as_handled()
			_navigate_main_button_vertical(1)
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_Z)):
			get_viewport().set_input_as_handled()
			var buttons := _get_main_buttons()
			if not buttons.is_empty() and _main_button_index >= 0 and _main_button_index < buttons.size():
				buttons[_main_button_index].pressed.emit()
