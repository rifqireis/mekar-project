extends Area2D

func _ready() -> void:
	area_entered.connect(_on_hit_player)
	body_entered.connect(_on_hit_player)

func _on_hit_player(other: Node2D) -> void:
	if other.is_in_group("player") or other.name == "MinigamePlayer" or other.name == "PlayerIcon":
		var pattern := _find_parent_pattern(self)
		if pattern:
			pattern.register_hit()
			
		queue_free()

func _find_parent_pattern(current_node: Node) -> AttackPattern:
	var parent := current_node.get_parent()
	while parent != null:
		if parent is AttackPattern:
			return parent as AttackPattern
		parent = parent.get_parent()
	return null
