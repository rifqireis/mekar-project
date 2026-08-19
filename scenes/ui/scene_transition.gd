extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color.a = 0.0

func change_scene(target_scene_path: String, duration: float = 0.5) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween_out: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween_out.tween_property(color_rect, "color:a", 1.0, duration)
	await tween_out.finished
	
	get_tree().change_scene_to_file(target_scene_path)
	
	await get_tree().process_frame
	
	var tween_in: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween_in.tween_property(color_rect, "color:a", 0.0, duration)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
