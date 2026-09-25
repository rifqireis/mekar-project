extends Node2D


func _ready() -> void:
	if PlayerRepository.is_snake_cleared:
		var snake_node = get_node_or_null("UlarEnggano")
		if snake_node:
			snake_node.queue_free()
			
		var tree_node = get_node_or_null("Meranti")
		if tree_node:
			tree_node.queue_free()


func _process(delta: float) -> void:
	pass
