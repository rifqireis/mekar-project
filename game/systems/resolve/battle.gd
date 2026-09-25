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
@onready var suppress_box: HBoxContainer = $Mode_Action/SubActionPanel/SuppressBox
@onready var observe_box: HBoxContainer = $Mode_Action/SubActionPanel/ObserveBox
@onready var engage_box: HBoxContainer = $Mode_Action/SubActionPanel/EngageBox
@onready var adapt_box: HBoxContainer = $Mode_Action/SubActionPanel/AdaptBox

@onready var player_hp_bar: ProgressBar = $FloatingBar/PlayerProfile/HPBar
@onready var player_str_bar: ProgressBar = $FloatingBar/PlayerProfile.get_node_or_null("STRBar")
@onready var enemy_hp_bar: ProgressBar = $FloatingBar/EnemyStats/HPBar
@onready var enemy_agt_bar: ProgressBar = $FloatingBar/EnemyStats/AgitationBar
@onready var trust_bar: ProgressBar = $FloatingBar/StandaloneTrustBar
@onready var stability_bar: ProgressBar = $FloatingBar/StandaloneStabilityBar
@onready var arena_decoration: TextureRect = $Mode_Minigame/ArenaDecoration

@onready var tutorial_panel: Control = $TutorialPanel
@onready var dodge_panel: Control = $TutorialPanel/DodgePanel
@onready var attack_panel: Control = $TutorialPanel/AttackPanel
@onready var engage_panel: Control = $TutorialPanel/EngagePanel
@onready var observe_panel: Control = $TutorialPanel/ObservePanel

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


	_reset_main_buttons_z_index()

	if dodge_panel: dodge_panel.hide()
	if attack_panel: attack_panel.hide()
	if engage_panel: engage_panel.hide()
	if observe_panel: observe_panel.hide()

	
	if PlayerRepository.current_enemy != null:
		enemy_resource = PlayerRepository.current_enemy
	
	assert(enemy_resource != null, "ERROR: Masukkan file .tres musuh di Inspector!")
	
	_setup_current_enemy()
	
	if enemy_sprite:
		default_enemy_pos = enemy_sprite.position
	
	_setup_button_labels()
	
	if player_hp_bar:
		player_hp_bar.max_value = PlayerRepository.max_hp
		
	_update_ui_bars()
	_apply_enemy_button_restrictions()
	
	_switch_mode(BattleMode.DIALOGUE)
	_handle_start_battle()


func _setup_current_enemy() -> void:
	var e_name: String = enemy_resource.enemy_name.to_lower()
	is_tree_enemy = ("pohon" in e_name or "meranti" in e_name or "tree" in e_name)
	is_tree_enraged = false
	observe_count = 0

	enemy_hp = enemy_resource.max_hp
	enemy_trust = 0
	enemy_stability = 0
	enemy_agitation = 0
	
	if "dialogue_resource" in enemy_resource and enemy_resource.get("dialogue_resource") != null:
		dialogue_resource = enemy_resource.get("dialogue_resource")
	
	_update_enemy_sprite_animation()


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


func _fetch_dialogue(title: String, override_delay: float = -1.0) -> void:
	if not dialogue_resource:
		return
		
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue_resource, title)

	while line != null:
		if speaker_name:
			speaker_name.text = line.character if not line.character.is_empty() else "DONGA"
		if log_text:
			log_text.text = line.text
			
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
	var btn_capture := suppress_box.get_node_or_null("BtnCapture/Label")
	if btn_capture: btn_capture.text = "* " + enemy_resource.suppress_3_name


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
	_reset_main_buttons_z_index()
	
	var main_container := $Mode_Action/MainButtonContainer
	var btn_suppress: BaseButton = main_container.get_node_or_null("BtnSuppress")
	var btn_observe: BaseButton = main_container.get_node_or_null("BtnObserve")
	var btn_engage: BaseButton = main_container.get_node_or_null("BtnEngage")
	
	if is_tree_enemy and is_tree_enraged and is_first_mad_tree_observe_hint:
		is_first_mad_tree_observe_hint = false
		if observe_panel: observe_panel.show()
		if engage_panel: engage_panel.hide()
		if btn_observe:
			btn_observe.z_index = 10
			btn_observe.grab_focus()
		return

	if is_tree_enemy and is_tree_enraged and is_first_mad_tree_engage_hint:
		is_first_mad_tree_engage_hint = false
		if observe_panel: observe_panel.hide()
		if engage_panel: engage_panel.show()
		if btn_engage:
			btn_engage.z_index = 10
			btn_engage.grab_focus()
		return

	if observe_panel: observe_panel.hide()
	if engage_panel: engage_panel.hide()
	if btn_suppress:
		btn_suppress.grab_focus()


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


func _on_btn_capture_pressed() -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	await _fetch_dialogue("capture_not_ready")
	_handle_player_turn()


func _execute_attack_minigame(speed_mod: float, damage_scale: float, base_hp: int, base_agit: int, dialogue_tag: String) -> void:
	sub_action_panel.hide()
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
	suppress_box.visible = false
	observe_box.visible = false
	engage_box.visible = false
	adapt_box.visible = false


func _on_btn_suppress_pressed() -> void:
	_hide_all_sub_action_boxes()
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_animate_pop_in(suppress_box)
	$Mode_Action/SubActionPanel/SuppressBox/BtnStrike.grab_focus()


func _on_btn_observe_pressed() -> void:
	if observe_panel:
		observe_panel.hide()
	_reset_main_buttons_z_index()
	
	_hide_all_sub_action_boxes()
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_animate_pop_in(observe_box)


func _on_btn_engage_pressed() -> void:
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
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_animate_pop_in(engage_box)


func _on_btn_adapt_pressed() -> void:
	_hide_all_sub_action_boxes()
	sub_action_panel.visible = true
	_animate_pop_in(sub_action_panel)
	_animate_pop_in(adapt_box)


func _on_sub_action_back_pressed() -> void:
	_animate_pop_out(sub_action_panel)
	_handle_player_turn()


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
	sub_action_panel.show()
	for child in sub_action_panel.get_children():
		child.visible = (child.name == "ItemBox")


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
		
	sub_action_panel.hide()
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
	sub_action_panel.hide()
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
	sub_action_panel.hide()
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
	return "arnoldos" in e_name or "rafflesia" in e_name


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
