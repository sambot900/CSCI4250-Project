extends Node2D

func _ready():
	# Connect the 'pressed' signal of the play_button to the _on_play_button_pressed() function
	#play_button.pressed.connect(_on_play_button_pressed)
	pass

func _process(_delta):
	pass

func _voice_sound1():
	var audio_player = $voice1
	var sound = load("res://Rev.mp3")
	audio_player.stream = sound
	audio_player.play()

func _success_sound():
	var audio_player = $"Success Sound Player"
	var sound = load("res://mixkit-game-success-alert-2039.wav")
	audio_player.stream = sound
	audio_player.play()

func _on_rich_text_label_guess():
	# CORRECT ANSWER PROMPTS NEXT SCREEN
	_success_sound()
	# Manual wait time to allow success sound to play...
	await get_tree().create_timer(2.0).timeout
	
	# Load next node
	var round_scene = load("res://Game.tscn")
	if round_scene == null:
		print("Failed to load the Round scene. Check the file path.")
		return
	var round_instance = round_scene.instantiate()

	# Add the Round scene as a child of the current scene
	get_tree().get_root().add_child(round_instance)
	
	# Ensure all nodes have time to process _exit_tree()
	await get_tree().process_frame

	queue_free()
