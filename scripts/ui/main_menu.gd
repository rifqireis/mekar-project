extends Control

func _ready():
	$PlayButton.grab_focus()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/cutscenes/introduction.tscn")

func _on_about_dev_button_pressed():
	# Ganti path ini sesuai dengan lokasi scene About Dev yang kamu buat nanti
	get_tree().change_scene_to_file("res://scenes/ui/about_dev.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_play_button_mouse_entered():
	$PlayButton.grab_focus()

func _on_about_dev_button_mouse_entered():
	$AboutDevButton.grab_focus()

func _on_exit_button_mouse_entered():
	$ExitButton.grab_focus()

func _on_sword_click_area_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("sword_animation")
