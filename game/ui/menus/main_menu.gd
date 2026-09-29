extends Control

@onready var mute_button: TextureButton = $MuteButton
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var unmuted_texture = preload("res://assets/ui/main_menu/MuteSoundBefore.png")
var muted_texture = preload("res://assets/ui/main_menu/MuteSoundAfter.png")

func _ready():
	$PlayButton.grab_focus()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://game/narrative/cutscenes/introduction.tscn")

func _on_about_dev_button_pressed():
	get_tree().change_scene_to_file("res://game/ui/menus/about_dev.tscn")

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
		
func _on_mute_button_pressed():
	# Toggle the Master audio bus mute (or you can use audio_player.stream_paused)
	var is_muted = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), !is_muted)
	
	# Swap the texture depending on the new state
	if is_muted:
		mute_button.texture_normal = unmuted_texture
	else:
		mute_button.texture_normal = muted_texture
