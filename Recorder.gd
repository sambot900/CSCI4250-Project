extends AudioStreamPlayer2D

var effect
var recording

func _ready():
	pass

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



func _on_game_perms() -> void:
	var idx = AudioServer.get_bus_index("Record")
	
	effect = AudioServer.get_bus_effect(idx, 0)
	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
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
