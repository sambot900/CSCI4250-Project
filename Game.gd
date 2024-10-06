extends Node2D

######################################################
# 	Root (Game)
######################################################

func _ready():
	adjust_background()
	get_viewport().connect("size_changed", Callable(self, "_on_size_changed"))
	
# If screen size is changed, usually this only applies to screen dragging on windows rather than 
# actual mobile app functionality.
func _on_size_changed():
	adjust_background()
	
	
func adjust_background():
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	# TODO:
	# Make adjustments to camera position with offsets


func _on_rich_text_label_guess():
	_success_sound()


func _success_sound():
	var audio_player = $"Success Sound Player"
	var sound = load("res://mixkit-game-success-alert-2039.wav")
	audio_player.stream = sound
	audio_player.play()
