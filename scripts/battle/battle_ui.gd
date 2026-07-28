extends Control

enum BattleMode { ACTION, DIALOGUE, MINIGAME }
var current_mode: BattleMode = BattleMode.DIALOGUE

enum BattleState { START_BATTLE, PLAYER_TURN, ENEMY_TURN, END_BATTLE }
var current_state: BattleState = BattleState.START_BATTLE

@export var enemy_resource: EnemyData

@export_group("Pengaturan Animasi UI")
@export var anim_duration: float = 0.25
@export var anim_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var anim_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Pengaturan Koreografi Dialog")
@export var enemy_dialogue_offset: Vector2 = Vector2(0.0, -60.0)


@onready var enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var floating_bar: Control = $FloatingBar
@onready var slanted_dialogue_box: Control = $Mode_Dialogue/SlantedDialogueBox

@onready var mode_action: Control = $Mode_Action
@onready var mode_dialogue: Control = $Mode_Dialogue
@onready var mode_minigame: Control = $Mode_Minigame

@onready var enemy_attack_container: SubViewportContainer = $Mode_Minigame/SubViewportContainer
@onready var enemy_attack_game: MinigameArena = $Mode_Minigame/SubViewportContainer/SubViewport/MinigameArena
@onready var player_attack_game: PlayerAttackGame = $Mode_Minigame/PlayerAttackGame

@onready var log_text: RichTextLabel = $Mode_Dialogue/SlantedDialogueBox/LogText
@onready var speaker_name: RichTextLabel = $Mode_Dialogue/SlantedDialogueBox/LogName

@onready var action_menu: Control = $Mode_Action/MainButtonContainer
@onready var sub_action_panel: TextureRect = $Mode_Action/SubActionPanel
@onready var suppress_box: HBoxContainer = $Mode_Action/SubActionPanel/SuppressBox
@onready var observe_box: HBoxContainer = $Mode_Action/SubActionPanel/ObserveBox
@onready var engage_box: HBoxContainer = $Mode_Action/SubActionPanel/EngageBox
@onready var adapt_box: HBoxContainer = $Mode_Action/SubActionPanel/AdaptBox

@onready var player_hp_bar: ProgressBar = $FloatingBar/PlayerProfile/HPBar
@onready var player_str_bar: ProgressBar = $FloatingBar/PlayerProfile/TrustBar
@onready var enemy_hp_bar: ProgressBar = $FloatingBar/EnemyStats/HPBar
@onready var enemy_agt_bar: ProgressBar = $FloatingBar/EnemyStats/AgitationBar
@onready var trust_bar: ProgressBar = $FloatingBar/StandaloneTrustBar
@onready var stability_bar: ProgressBar = $FloatingBar/StandaloneStabilityBar

var default_enemy_pos: Vector2 = Vector2.ZERO

var enemy_hp: int = 100
var enemy_trust: int = 0
var enemy_stability: int = 0
var enemy_agitation: int = 0

var observe_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	
	if PlayerRepository.current_enemy != null:
		enemy_resource = PlayerRepository.current_enemy
	
	assert(enemy_resource != null, "ERROR: Masukkan file .tres musuh di Inspector!")
	
	if enemy_sprite:
		default_enemy_pos = enemy_sprite.position
		
	_setup_button_labels()
	
	if player_hp_bar:
		player_hp_bar.max_value = PlayerRepository.max_hp
		
	_update_ui_bars()
	
	_switch_mode(BattleMode.DIALOGUE)
	_handle_start_battle()

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
			
	else:
		if enemy_sprite:
			tween.tween_property(enemy_sprite, "position", default_enemy_pos, anim_duration)
			
		if floating_bar:
			floating_bar.show()
			tween.tween_property(floating_bar, "modulate:a", 1.0, anim_duration)
			
		if mode == BattleMode.ACTION:
			_animate_pop_in(mode_action)

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
	speaker_name.text = enemy_resource.enemy_name
	log_text.text = enemy_resource.intro_text
	await get_tree().create_timer(2.5).timeout
	change_state(BattleState.PLAYER_TURN)

func _handle_player_turn() -> void:
	_switch_mode(BattleMode.ACTION)
	sub_action_panel.visible = false
	$Mode_Action/MainButtonContainer/BtnSuppress.grab_focus()

func _handle_enemy_turn() -> void:
	_switch_mode(BattleMode.DIALOGUE)
	speaker_name.text = enemy_resource.enemy_name
	log_text.text = enemy_resource.turn_text
	await get_tree().create_timer(1.8).timeout
	
	_switch_mode(BattleMode.MINIGAME)
	player_attack_game.visible = false
	enemy_attack_container.visible = true
	
	enemy_attack_game.start_phase(enemy_resource, enemy_agitation)
	
	var total_hits: int = await enemy_attack_game.minigame_finished
	
	_switch_mode(BattleMode.DIALOGUE)
	_resolve_enemy_damage(total_hits)
	
func _handle_end_battle() -> void:
	_switch_mode(BattleMode.DIALOGUE)
	
	await get_tree().create_timer(3.0).timeout
	
	PlayerRepository.end_battle(true)

func _on_btn_strike_pressed() -> void:
	_execute_attack_minigame(1.0, 1.0, enemy_resource.suppress_1_hp, enemy_resource.suppress_1_agit, enemy_resource.suppress_1_log)

func _on_btn_heavy_strike_pressed() -> void:
	_execute_attack_minigame(1.6, 1.8, enemy_resource.suppress_2_hp, enemy_resource.suppress_2_agit, enemy_resource.suppress_2_log)

func _on_btn_capture_pressed() -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	speaker_name.text = "INFO"
	log_text.text = "* Donga mencoba mencari celah untuk menangkap anomali... (Belum siap!)"
	await get_tree().create_timer(1.5).timeout
	_handle_player_turn()

func _execute_attack_minigame(speed_mod: float, damage_scale: float, base_hp: int, base_agit: int, action_log: String) -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.MINIGAME)
	enemy_attack_container.visible = false
	player_attack_game.visible = true
	
	player_attack_game.start_phase(speed_mod)
	var accuracy_score: float = await player_attack_game.minigame_finished
	
	_switch_mode(BattleMode.DIALOGUE)
	_resolve_player_attack(accuracy_score, damage_scale, base_hp, base_agit, action_log)

func _resolve_player_attack(score: float, damage_scale: float, base_hp: int, base_agit: int, action_log: String) -> void:
	speaker_name.text = "SISTEM"
	
	if score > 0.0:
		var raw_damage := absf(float(base_hp)) * damage_scale
		var calculated_damage := roundi(raw_damage * score)
		enemy_hp = clampi(enemy_hp - calculated_damage, 0, 100)
		
		var calculated_agit := roundi(absf(float(base_agit)) * score)
		enemy_agitation = clampi(enemy_agitation + calculated_agit, 0, 100)
		
		log_text.text = action_log + " (Damage: " + str(calculated_damage) + ". Accuration: " + str(roundi(score * 100)) + "%)"
	else:
		log_text.text = "* Serangan Donga meleset Rafflesia tertawa tanpa terluka"
	
	_finalize_player_action()

func _finalize_player_action() -> void:
	_update_ui_bars()
	await get_tree().create_timer(2.0).timeout
	
	if _check_victory_conditions():
		change_state(BattleState.END_BATTLE)
	else:
		change_state(BattleState.ENEMY_TURN)

func _resolve_enemy_damage(total_hits: int) -> void:
	speaker_name.text = "SISTEM"
	var final_damage := 0
	
	if total_hits > 0:
		var base_damage := float(enemy_resource.base_damage)
		if enemy_agitation >= 50:
			base_damage = float(enemy_resource.rage_damage)
			
		var severity := clampf(float(total_hits) / 60.0, 0.2, 1.0)
		final_damage = roundi(base_damage * severity)
		log_text.text = "* Donga terluka Terkena " + str(final_damage) + " damage."
	else:
		log_text.text = "* Donga bergerak cepat! Berhasil menghindari semua damage."
		
	#player_hp = clampi(player_hp - final_damage, 0, 100)
	PlayerRepository.take_damage(final_damage)
	enemy_agitation = clampi(enemy_agitation + 10, 0, 100)
	_update_ui_bars()
	
	await get_tree().create_timer(2.0).timeout
	
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
	_hide_all_sub_action_boxes()
	sub_action_panel.visible = true
	
	_animate_pop_in(sub_action_panel)
	_animate_pop_in(observe_box)

func _on_btn_engage_pressed() -> void:
	if observe_count < 3:
		_switch_mode(BattleMode.DIALOGUE)
		speaker_name.text = "INFO"
		log_text.text = "* Analisis data belum cukup! Lakukan OBSERVE minimal 3 kali."
		await get_tree().create_timer(2.0).timeout
		_switch_mode(BattleMode.ACTION)
		return
		
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
		
	print(enemy_hp)

func _check_victory_conditions() -> bool:
	if PlayerRepository.hp <= 0:
		log_text.text = "* Donga kehabisan energi... Investigasi Gagal!"
		return true
	
	if enemy_hp <= 0:
		log_text.text = "* Anomali berhasil dilumpuhkan secara fisik. (Jalur Tekan)"
		return true
		
	if enemy_trust >= 100:
		log_text.text = "* Rafflesia berhenti menyerang. Ia merasa dipahami dan percaya padamu! (Jalur Damai)"
		return true
		
	if enemy_stability >= 100:
		log_text.text = "* Ekosistem pulih! Rafflesia tenang kembali karena habitatnya terestorasi. (Jalur Restorasi)"
		return true
		
	return false

func _on_btn_item_pressed() -> void:
	sub_action_panel.show()
	for child in sub_action_panel.get_children():
		child.visible = (child.name == "ItemBox")

func _on_btn_species_pressed() -> void:
	_resolve_observe("Spesies: Rafflesia Urbanis", 10)

func _on_btn_status_pressed() -> void:
	_resolve_observe("Status: Tertekan (Distressed) akibat invasi beton kota", 10)

func _on_btn_cause_pressed() -> void:
	_resolve_observe("Penyebab: Kehilangan habitat asli dan kekurangan nutrisi", 15)

func _resolve_observe(info_result: String, trust_gain: int) -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	if speaker_name:
		speaker_name.text = "SISTEM"
	
	observe_count += 1
	enemy_trust = clampi(enemy_trust + trust_gain, 0, 100)
	_update_ui_bars()
	
	var log_message := "* Donga mengamati target -> " + info_result + ". (Trust +" + str(trust_gain) + ")"
	
	if observe_count >= 3:
		log_message += "\n* [INFO]: Akar masalah dipahami! Entri Tambo terbuka & AJAK BICARA (Engage) kini aktif!"
		# btn_engage.disabled = false
		
	log_text.text = log_message
	_finalize_player_action()

func _on_btn_choice_a_pressed() -> void:
	_resolve_engage(true, "Kami tahu kotalah yang merebut tanahmu. Kami ingin mencari jalan tengah.", 25)

func _on_btn_choice_b_pressed() -> void:
	_resolve_engage(false, "Kembali ke hutan sekarang atau kami akan membakar akarmu!", 15)

func _on_btn_choice_c_pressed() -> void:
	_resolve_engage(true, "Donga menurunkan senjata dan memperlihatkan bibit tanaman baru.", 20)

func _on_btn_choice_d_pressed() -> void:
	_resolve_engage(false, "Dasar monster parasit pemakan beton!", 15)

func _resolve_engage(is_correct: bool, dialogue_text: String, trust_change: int) -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	if speaker_name:
		speaker_name.text = "DONGA"
	
	if is_correct:
		enemy_trust = clampi(enemy_trust + trust_change, 0, 100)
		_update_ui_bars()
		log_text.text = '"' + dialogue_text + '"\n* Rafflesia mendengarkan, akarnya perlahan melemas. (Trust +' + str(trust_change) + ')'
		
		if enemy_trust >= 50 and enemy_trust < 100:
			log_text.text += "\n* [STATUS]: Agresi musuh menurun!"
	else:
		enemy_trust = clampi(enemy_trust - trust_change, 0, 100)
		enemy_agitation = clampi(enemy_agitation + 15, 0, 100)
		_update_ui_bars()
		log_text.text = '"' + dialogue_text + '"\n* Kata-kata Donga malah memicu amarah anomali! (Trust -' + str(trust_change) + ' | Agitasi +15)'
		
	_finalize_player_action()

func _on_btn_water_pressed() -> void:
	_resolve_adapt("Mengalirkan air bersih ke tanah yang kering", 25, 10)

func _on_btn_plant_pressed() -> void:
	_resolve_adapt("Menanam bibit restorasi di sekitar akar Rafflesia", 35, 15)

func _on_btn_path_pressed() -> void:
	_resolve_adapt("Membuka jalur gorong-gorong agar akarnya bisa bermigrasi", 20, 10)

func _on_btn_trap_pressed() -> void:
	_resolve_adapt("Membongkar perangkap logam milik perusahaan yang menjepit target", 20, 20)

func _resolve_adapt(action_name: String, stability_gain: int, trust_gain: int) -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	if speaker_name:
		speaker_name.text = "DONGA"
	
	enemy_stability = clampi(enemy_stability + stability_gain, 0, 100)
	enemy_trust = clampi(enemy_trust + trust_gain, 0, 100)
	_update_ui_bars()
	
	log_text.text = "* Donga bertindak: " + action_name + "!\n* Kondisi ekosistem membaik! (Stability +" + str(stability_gain) + " | Trust +" + str(trust_gain) + ")"
	
	_finalize_player_action()

func _on_btn_ramuan_akar_pressed() -> void:
	sub_action_panel.hide()
	_switch_mode(BattleMode.DIALOGUE)
	if speaker_name:
		speaker_name.text = "DONGA"
	
	var heal_amount: int = 30
	#PlayerRepository.hp = clampi(player_hp + heal_amount, 0, 100)
	PlayerRepository.heal(heal_amount)
	
	log_text.text = "* Donga meminum [1x] Ramuan Akar. Stamina dan luka fisik pulih kembali! (HP +" + str(heal_amount) + ")"
	_finalize_player_action()
