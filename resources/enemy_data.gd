class_name EnemyData
extends Resource


@export_category("Enemy Profile")
@export var enemy_name: String = "lorem ipsum"
@export_multiline var intro_text: String = "* *NamaEnemy* muncul menghalangi jalan!"
@export_multiline var turn_text: String = "* *NamaEnemy* bersiap menyerang..."
@export var base_damage: int = 15
@export var rage_damage: int = 25

@export_group("Pola Serangan (Bullet Hell)")
@export var normal_patterns: Array[PackedScene]
@export var rage_patterns: Array[PackedScene]

@export_category("Sub-Action: SUPPRESS")
@export var suppress_1_name: String = "Strike"
@export var suppress_1_log: String = "* Donga melancarkan Strike!"
@export var suppress_1_hp: int = -15
@export var suppress_1_trust: int = -5
@export var suppress_1_agit: int = 10

@export var suppress_2_name: String = "Heavy Strike"
@export var suppress_2_log: String = "* Donga melancarkan Heavy Strike!"
@export var suppress_2_hp: int = -35
@export var suppress_2_trust: int = -15
@export var suppress_2_agit: int = 25

@export var suppress_3_name: String = "Capture"
@export var suppress_3_log: String = "* Donga mencoba melakukan Capture!"
@export var suppress_3_hp: int = 0
@export var suppress_3_trust: int = 0
@export var suppress_3_agit: int = 15

@export_category("Sub-Action: OBSERVE")
@export var observe_1_name: String = "Species"
@export var observe_1_log: String = "* Lorem ipsum dolor sit amet!"
@export var observe_2_name: String = "Status"
@export var observe_2_log: String = "* Lorem ipsum dolor sit amet!"

@export_category("Sub-Action: ENGAGE")
@export var engage_1_name: String = "Opsi Dialog A"
@export var engage_1_log: String = "* Lorem ipsum dolor sit amet!"
@export var engage_1_trust: int = 35
@export var engage_1_agit: int = 0

@export var engage_2_name: String = "Opsi Dialog B"
@export var engage_2_log: String = "* Lorem ipsum dolor sit amet!"
@export var engage_2_trust: int = -15
@export var engage_2_agit: int = 15

@export_category("Sub-Action: ADAPT")
@export var adapt_1_name: String = "Water Soil"
@export var adapt_1_log: String = "* Lorem ipsum dolor sit amet!"
@export var adapt_1_stability: int = 50
@export var adapt_1_trust: int = 15

@export var adapt_2_name: String = "Plant Seeds"
@export var adapt_2_log: String = "* Lorem ipsum dolor sit amet!"
@export var adapt_2_stability: int = 35
@export var adapt_2_trust: int = 0

@export_category("Minigame System Configuration")
@export var minigame_duration: float = 4.0
@export var obstacle_spawn_rate: float = 0.4
@export var basic_attack_scene: PackedScene  
@export var special_attack_scene: PackedScene

@export_group("Data Interaksi & Observasi")
@export var observe_species: String = "Spesies: Rafflesia Urbanis"
@export var observe_status: String = "Status: Tertekan (Distressed) akibat invasi beton kota"
@export var observe_cause: String = "Penyebab: Kehilangan habitat asli dan kekurangan nutrisi"

@export_group("Data Pilihan Engage (A/B/C/D)")
@export var engage_choices: Array[Dictionary] = [
	{"text": "Kami tahu kotalah yang merebut tanahmu...", "correct": true, "trust": 25},
	{"text": "Kembali ke hutan sekarang atau kami bakar akarmu!", "correct": false, "trust": 15},
	{"text": "Donga menurunkan senjata dan memperlihatkan bibit...", "correct": true, "trust": 20},
	{"text": "Dasar monster parasit pemakan beton!", "correct": false, "trust": 15}
]

@export_group("Dialog Penutup")
@export_multiline var defeat_by_hp: String = "* Target berhasil dikalahkan."
@export_multiline var defeat_by_trust: String = "* Pendekatan damai berhasil. Target mundur."
@export_multiline var defeat_by_stability: String = "* Ekosistem pulih! Anomali kehilangan alasannya untuk menyerang."
