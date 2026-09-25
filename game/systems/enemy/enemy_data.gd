extends Resource
class_name EnemyData

@export var enemy_name: String = "Musuh"
@export var max_hp: int = 100
@export var base_damage: int = 10
@export var rage_damage: int = 20

@export var dialogue_resource: DialogueResource

@export_group("Attack Patterns (Minigame)")
@export var normal_patterns: Array[PackedScene] = []
@export var rage_patterns: Array[PackedScene] = []

@export_group("Suppress Actions")
@export var suppress_1_name: String = "Pukul"
@export var suppress_1_hp: int = 20
@export var suppress_1_agit: int = 15

@export var suppress_2_name: String = "Pukul Berat"
@export var suppress_2_hp: int = 40
@export var suppress_2_agit: int = 30

@export var suppress_3_name: String = "Tangkap"

@export_group("Observe Values")
@export var observe_species_trust: int = 10
@export var observe_status_trust: int = 10
@export var observe_cause_trust: int = 15

@export_group("Engage Values")
@export var choice_a_is_correct: bool = true
@export var choice_a_trust: int = 25

@export var choice_b_is_correct: bool = false
@export var choice_b_trust: int = 15

@export var choice_c_is_correct: bool = true
@export var choice_c_trust: int = 20

@export var choice_d_is_correct: bool = false
@export var choice_d_trust: int = 15

@export_group("Adapt Values")
@export var adapt_water_stability: int = 25
@export var adapt_water_trust: int = 10

@export var adapt_plant_stability: int = 35
@export var adapt_plant_trust: int = 15

@export var adapt_path_stability: int = 20
@export var adapt_path_trust: int = 10

@export var adapt_trap_stability: int = 20
@export var adapt_trap_trust: int = 20
