extends Area2D

@export var enemy_data: EnemyData
@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "meranti_angry"

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if has_triggered:
		return

	if body.is_in_group("player"):
		has_triggered = true
		_start_encounter_sequence(body)

func _start_encounter_sequence(player: CharacterBody2D) -> void:
	if "is_in_cutscene" in player:
		player.is_in_cutscene = true
		player.velocity = Vector2.ZERO
		if player.animated_sprite:
			player.animated_sprite.stop()

	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
		await DialogueManager.dialogue_ended
	else:
		push_warning("Pohon Meranti: DialogueResource belum dimasukkan di Inspector!")

	if not enemy_data:
		push_error("ERROR: File enemy_data (.tres) Pohon Meranti belum dimasukkan di Inspector!")
		if "is_in_cutscene" in player:
			player.is_in_cutscene = false
		return

	PlayerRepository.start_battle(
		enemy_data,
		player.global_position,
		get_tree().current_scene.scene_file_path
	)
