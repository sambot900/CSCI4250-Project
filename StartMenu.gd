extends Node2D

@onready var play_button = $"Play Button"

func _ready():
	# Connect the 'pressed' signal of the play_button to the _on_play_button_pressed() function
	play_button.pressed.connect(_on_play_button_pressed)

func _process(_delta):
	pass


func _on_play_button_pressed():
	print("1")
	var round_scene = load("res://Game.tscn")
	if round_scene == null:
		print("Failed to load the Round scene. Check the file path.")
		return
	var round_instance = round_scene.instantiate()

	# Add the Round scene as a child of the current scene
	get_tree().get_root().add_child(round_instance)

	queue_free()
