extends AudioStreamPlayer2D
var effect
var recording


# Called when the node enters the scene tree for the first time.
func _ready():
	var idx = AudioServer.get_bus_index("Record")
	
	effect = AudioServer.get_bus_effect(idx, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_menu_toggle_record():
	if effect.is_recording_active():
		recording = effect.get_recording()
		effect.set_recording_active(false)
		print("record toggle: off")
	else:
		effect.set_recording_active(true)
		print("record toggle: on")

	if recording:
		var save_path = "res://Audio Bits/"
		recording.save_to_wav(save_path)
		print("saved to ",save_path)
