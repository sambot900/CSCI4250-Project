extends Node2D

signal perms

var speech_recognizer
var partialResultLabel
var answer_list = ["play", "hay", "pray"]
var image_path
var control_node_ref: Control = null
var visual_prompt_dictionary = {}
var audio_prompt_dictionary = {}
var left_to_solve_array = []
var guess_string = ""
var answer_string = ""

func _ready():
	# Fill up our dictionaries with prompts (audio and visual)
	visual_prompt_dictionary["horse"] = [["horse","force", "course"], "res://Assets/Prompts/horse.png"]
	visual_prompt_dictionary["rabbit"] = [["rabbit"], "res://Assets/Prompts/rabbit.png"]
	visual_prompt_dictionary["dog"] = [["dog", "hog", "dob"], "res://Assets/Prompts/dog.png"]
	
	# Fill up our list of unsolved prompts with animals
	refill_left_to_solve()
	
	# Instantiate transcription script node and a label to display the transcriptions for
	# debugging purposes... this is not visible by deafult.
	speech_recognizer = $Transcription
	partialResultLabel = $PartialResultLabel

	# Running on Android
	if OS.get_name() == "Android":
		var permission = "android.permission.RECORD_AUDIO"
		OS.connect("permission_request_result", Callable(self, "_on_permission_result"))
		OS.request_permission(permission)
		partialResultLabel.text = "Running on Android."
		_initialize_app()
	else:
	# Not running on Android
		partialResultLabel.text = "Not running on Android."
		_initialize_app()

	# Android: Microphone permission granted
func _on_permission_granted(permission_name):
	if permission_name == "android.permission.RECORD_AUDIO":
		print("Microphone permission granted.")
		partialResultLabel.text = "Microphone permission granted."
		_initialize_app()
		
# Android: Microphone permission denied
func _on_permission_denied(permission_name):
	if permission_name == "android.permission.RECORD_AUDIO":
		print("Microphone permission denied.")
		partialResultLabel.text = "Microphone permission denied."
		# Disconnect signals
		_handle_permission_denied()

# Connect with transcription script and the signals it emits
# Start speech recognition
func _initialize_app():
	print("Game: Initializing...")
	speech_recognizer.connect("OnPartialResult", Callable(self, "_on_test_script_on_partial_result"))
	speech_recognizer.connect("OnFinalResult", Callable(self, "_on_test_script_on_final_result"))
	speech_recognizer.StartSpeechRecognition()

# Debug: Need user permission for microphone access
func _handle_permission_denied():
	# Inform the user that the app requires the microphone permission
	print("This app requires microphone access to function properly.")
	partialResultLabel.text = "Microphone permission is required."

func _process(_delta):
	pass

func _success_sound():
	var audio_player = $SuccessSoundPlayer
	var sound = load("res://Audio/mixkit-game-success-alert-2039.wav")
	audio_player.stream = sound
	audio_player.play()
	
# If we solve all prompts, this ensures we don't end up in an infinite loop
# by refilling our available prompts when they are exhausted (excluding the most
# recent to prevent back-to-back prompts)
func refill_left_to_solve():
	for key in visual_prompt_dictionary.keys():
		left_to_solve_array.append(key)
	print("refill_left_to_solve: REFRESHED")
	
# Get random prompt from unsolved prompts
func get_random_prompt(dictionary: Dictionary, previous: String) -> Array:
	left_to_solve_array.erase(previous)
	if left_to_solve_array == []:
		refill_left_to_solve()
	left_to_solve_array.erase(previous)
	var random_key
	var keys = dictionary.keys()
	random_key = keys[randi() % keys.size()]  # Select a random key
	while random_key not in left_to_solve_array:
		random_key = keys[randi() % keys.size()]
	return dictionary[random_key]  # Return the value associated with the random key

# Not really using this with our continuous mic use.
func _on_test_script_on_final_result(finalResults: String) -> void:
	print("Final Recognized speech: ", finalResults)

# When the script outputs transcribed text, it will trigger this function.
func _on_test_script_on_partial_result(partialResults: String) -> void:
	print("Partial Recognized speech: ", partialResults)
	partialResultLabel.text = partialResults
	var last_word

	# JSON instnce to parse text results
	var json = JSON.new()
	var error_code = json.parse(partialResults)
	
	# Convert JSON output to a singular guess word if no errors in JSON parse
	if error_code == OK:
		var parsed_json = json.get_data()  # Get the parsed JSON data
		var text = parsed_json.get("partial", "")  # Access the "partial" value
		var words = text.split(" ")
		last_word = words[-1].strip_edges().to_lower()
		print("GUESS: ", last_word)

		# Check correctness of guess
		# If correct, move to next prompt
		if last_word in answer_list:
			_success_sound()
			speech_recognizer.StopSpeechRecognition()
			_next_prompt()
	else:
		print("Error parsing JSON: ", json.error_string)

# This creates nodes to display a prompt
func create_centered_control_node():
	control_node_ref = Control.new()

	# VBoxContainer setup
	# This is a box that displays a column of nodes; in our case it is filled
	# with the animal image and then the prompt blank below it.
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# TextureRect setup
	# This instantiates the prompt image
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(image_path)
	texture_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	texture_rect.anchor_left = 0.5
	texture_rect.anchor_right = 0.5
	texture_rect.anchor_top = 0.5
	texture_rect.anchor_bottom = 0.5
	#texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var pad_x = (get_viewport().size.x - texture_rect.texture.get_width()) / 2
	var pad_y = (get_viewport().size.y - texture_rect.texture.get_height()) / 3

	# Label setup
	# This instantiates the prompt guess/answer blank
	var guess_label = Label.new()
	var answer_label = Label.new()
	
	guess_string = ""
	answer_string = ""
	
	for letter in answer_list[0]:
		guess_string = guess_string + "_"
		answer_string = answer_string + letter
		guess_string = guess_string + "  "
		answer_string = answer_string + "  "
	
	guess_label.text = guess_string
	guess_label.add_theme_font_size_override("font_size", 72)
	guess_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	answer_label.text = answer_string
	answer_label.add_theme_font_size_override("font_size", 72)
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	guess_label.visible = true
	answer_label.visible = false
	#label.horizontal_alignment = Label.PRESET_CENTER

	# Add nodes to hierarchy
	vbox.add_child(texture_rect)
	vbox.add_child(guess_label)
	control_node_ref.add_child(vbox)
	$MainWindow.add_child(control_node_ref)

	# Add the Control node to the current scene
	#add_child(control_node_ref)
	control_node_ref.offset_left = pad_x
	control_node_ref.offset_top = pad_y
	
	
	print("get_viewport().size.x: ",get_viewport().size.x," texture_rect.texture.get_width() ", texture_rect.texture.get_width())

# This clears the screen of a prompt so that we can add a new one
func remove_control_node():
	if control_node_ref:
		control_node_ref.queue_free()
		control_node_ref = null

func _next_prompt():
	# If we are moving away from the start menu, we need to hide it's elements
	if answer_list[0] == "play":
		$Background/StartMenuPrompt.visible = false
		$Background/StartMenuLogo.visible = false
		
	# Get a random prompt
	var new_prompt = get_random_prompt(visual_prompt_dictionary, answer_list[0])
	answer_list = new_prompt[0]
	image_path = new_prompt[1]
	
	# Clear old prompt, and populate new prompt
	remove_control_node()
	create_centered_control_node()
	speech_recognizer.StartSpeechRecognition()
