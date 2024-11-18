extends Node2D

#region Globals
######################################################################

var guess_label
var speech_recognizer
var partialResultLabel
var play_list = ["play", "hay", "pray", "why", "boy", "by", "i"]
var answer_list = ["play", "hay", "pray", "why", "boy", "by", "i"]
var image_path
var control_node_ref: Control = null
var visual_prompt_dictionary = {}
var audio_prompt_dictionary = {}
var left_to_solve_array = []
var guess_string = ""
var answer_string = ""
var score = 0
var gamemode_list = [["one", "won", "young", "pictures", "pitchers"], ["two", "to", "too", "do", "sounds", "found"], ["three", "both", "oath", "next"]]
var gamemode = ""
var gamemode_select = false
var star_animation_in_progress = false
#endregion

func _ready():
	
	# init asset visibility
	$Background/Control/CountNumber.visible = false
	$Background/StartMenuPrompt.visible = true
	$Background/Logo.visible = true
	$Background/Logo/Animal.visible = true
	$Background/Logo/Scramble.visible = true
	$Score.visible = false
	$Background/BlackScreen.visible = false
	$Star.visible = false
	$Score.visible = false
	$Background/RoundBgShadow.visible = false
	$Background/Cards.visible = false
	$Background/Cards/CardOne.visible = false
	$Background/Cards/CardTwo.visible = false
	$Background/Cards/CardThree.visible = false
	
	# Fill up our dictionaries with prompts (audio and visual)
	visual_prompt_dictionary["horse"] = [["horse","force", "course", "or", "source"], "res://Assets/Prompts/horse.png"]
	visual_prompt_dictionary["rabbit"] = [["rabbit", "reset", "radish", "rabbid"], "res://Assets/Prompts/rabbit.png"]
	visual_prompt_dictionary["dog"] = [["dog", "hog", "dob", "da"], "res://Assets/Prompts/dog.png"]
	visual_prompt_dictionary["cat"] = [["cat", "ka", "kurt", "can", "get", "cap"], "res://Assets/Prompts/cat.png"]
	visual_prompt_dictionary["lion"] = [["lion", "i", "i'm"], "res://Assets/Prompts/lion.png"]
	visual_prompt_dictionary["panda"] = [["panda", "handa", "the"], "res://Assets/Prompts/panda.png"]
	visual_prompt_dictionary["cow"] = [["cow", "cao", "go"], "res://Assets/Prompts/cow.png"]
	visual_prompt_dictionary["elephant"] = [["elephant"], "res://Assets/Prompts/elephant.png"]
	visual_prompt_dictionary["giraffe"] = [["giraffe"], "res://Assets/Prompts/giraffe.png"]
	visual_prompt_dictionary["penguin"] = [["penguin"], "res://Assets/Prompts/penguin.png"]
	visual_prompt_dictionary["eagle"] = [["eagle"], "res://Assets/Prompts/eagle.png"]
	visual_prompt_dictionary["alligator"] = [["alligator"], "res://Assets/Prompts/alligator.png"]
	visual_prompt_dictionary["shark"] = [["shark"], "res://Assets/Prompts/shark.png"]

	# Fill up our list of unsolved prompts with animals
	refill_left_to_solve()
	
	# For our randint() method seed
	randomize()
	
	# Transcription script node
	speech_recognizer = $Transcription
	
	# Label to display the transcriptions for
	# debugging purposes... this is not visible by deafult.
	partialResultLabel = $PartialResultLabel
	

#region Android perms
######################################################################

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
		
		# Debug: Need user permission for microphone access
func _handle_permission_denied():
	# Inform the user that the app requires the microphone permission
	print("This app requires microphone access to function properly.")
	partialResultLabel.text = "Microphone permission is required."

#endregion

func _process(_delta):
	# Label to display score is updated every tick
	$Score/StarScoreLabel.text = str(score)

# Connect with transcription script and the signals it emits
# Start speech recognition
func _initialize_app():
	print("Game: Initializing...")
	#speech_recognizer.connect("OnPartialResult", Callable(self, "_on_test_script_on_partial_result"))
	#speech_recognizer.connect("OnFinalResult", Callable(self, "_on_test_script_on_final_result"))
	_start_menu_music()
	speech_recognizer.StartSpeechRecognition()
	$MicTimer.start()
	$Background/AnimateMenuImages.play("menu_images")
	$Background/Logo/AnimateLogo.play("logo")
	$Background/PromptBlink.play("prompt_blink")
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
	return dictionary[random_key]  # Return the value of the random key

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

		if gamemode == "":
			var picture_mode = gamemode_list[0]
			var sound_mode = gamemode_list[1]
			var mixed_mode = gamemode_list[2]
			if last_word in picture_mode:
				gamemode = "picture_mode"
				guess_success(last_word)
			elif last_word in sound_mode:
				gamemode = "sound_mode"
				guess_success(last_word)
			elif last_word in mixed_mode:
				gamemode = "mixed_mode"
				guess_success(last_word)
		# Check correctness of guess
		# If correct, move to next prompt
		if last_word in answer_list:
			speech_recognizer.StopSpeechRecognition()
			guess_success(last_word)
	else:
		print("Error parsing JSON: ", json.error_string)

func guess_success(answer: String):
	if answer in play_list:
		$MicTimer.stop()
		$Background/Logo/AnimateLogo.stop()
		_low_menu_music()
		_start_sound()
		$Background/AnimateMenuImages/AnimateMenuImagesFadeOut.play("menu_images_fade_out")
		$Background/ProceedPastStart.play("proceed_past_start")
		$Background/PromptBlink.stop()
	elif gamemode_select:
		$MicTimer.stop()
		$MicTimer.start()
		_mode_select_sound()
		_card_select_sound()
		remove_gamemode_selection()
		$Background/Cards.visible = true
		$Background/Cards/CardOne.visible = true
		$Background/Cards/CardTwo.visible = true
		$Background/Cards/CardThree.visible = true
		if gamemode == "picture_mode":
			gamemode_select = false
			$Background/AnimateCards.play("cards_1")
		elif gamemode == "sound_mode":
			gamemode_select = false
			$Background/AnimateCards.play("cards_2")
		elif gamemode == "mixed_mode":
			gamemode_select = false
			$Background/AnimateCards.play("cards_3")
			
		
	else:
		set_answer_label_text()
		_success_sound()
		star_animation_in_progress = true
		$Background/Timer.stop()
		$Star/AnimateStar.play("star")
		_low_round_music()
		
#region onFinished Animations

# When proceed past start menu
func _on_proceed_past_start_animation_finished(anim_name: StringName) -> void:
	star_animation_in_progress = false
	$Background/StartMenuPrompt.visible = false
	$Background/Logo.visible = false
	$Score.visible = true
	$Background/BlackScreen.visible = false
	$Star.visible = false
	$Star/StarSprite.visible = false
	_game_mode_selection()

# Stop menu images animation after leaving start menu
func _on_animate_menu_images_fade_out_animation_finished(anim_name: StringName) -> void:
	$Background/AnimateMenuImages.stop()

# Star animation finished (scored a point)
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	score += 1
	_coin_sound()
	_next_prompt()

func _on_animate_cards_animation_finished(anim_name: StringName) -> void:
	$Background/FadeOut.play("fade_out")

# Black fade "out" is finished
func _on_fade_out_animation_finished(anim_name: StringName) -> void:
	_stop_menu_music()
	$Score/Star.visible = true
	$Score/StarScoreLabel.visible = true
	$Background/FadeIn.play("fade_in_sound")
	$Background/RoundBgShadow.visible = true
	$Background/Cards.visible = false
	$Background/Cards/CardOne.visible = false
	$Background/Cards/CardTwo.visible = false
	$Background/Cards/CardThree.visible = false

# Black fade "in" is finished
func _on_fade_in_animation_finished(anim_name: StringName) -> void:
	$Background/AnimateBackground.play("round_countdown")

# A background animation is complete
func _on_animate_background_animation_finished(anim_name: StringName) -> void:
	
	# Round countdown is complete
	if anim_name == "round_countdown":
		_start_round_music()
		$MicTimer.stop()
		_next_prompt()

func set_answer_label_text():
	if answer_list[0] == null:
		answer_list[0] == "get_answer_label_text(): answer_title[0] is null"
	var answer = ""
	var length = answer_list[0].length() - 1
	var count = 0
	for letter in answer_list[0]:
		answer = answer + letter
		if count < length:
			answer = answer + "  "
		count += 1
	# Display answer to player
	guess_label.text = answer.to_upper()

func _fail_prompt():
	if answer_list[0] == null:
		_next_prompt()
	else:
		speech_recognizer.StopSpeechRecognition()
		_fail_sound()
		
		set_answer_label_text()
		await sleep(2)
		
		_next_prompt()
		#$animation.play("fail_prompt")

# Player fails prompt (runs out of time)
func _on_timer_animation_finished(anim_name: StringName) -> void:
	_fail_prompt()
	
#endregion

# This populates prompt graphics during a round
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
	guess_label = Label.new()
	
	answer_string = answer_list[0]
	var hint_string = generate_hint_string(answer_string)
	
	guess_label.text = hint_string
	guess_label.add_theme_font_size_override("font_size", 72)
	guess_label.add_theme_color_override("font_color", Color(255, 255, 255))
	guess_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	
	guess_label.visible = true
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
	
	
	#print("get_viewport().size.x: ",get_viewport().size.x," texture_rect.texture.get_width() ", texture_rect.texture.get_width())

func create_gamemode_selection():
	# Lists for titles and descriptions
	var title = "Choose Game Mode!"
	var descriptions = ["","",""]
	var images = ["res://Assets/UI/mode_card_1.png","res://Assets/UI/mode_card_2.png","res://Assets/UI/mode_card_3.png"]
	var title_label
	
	# Create the main control node
	control_node_ref = Control.new()
	control_node_ref.anchor_left = 0
	control_node_ref.anchor_right = 1
	control_node_ref.anchor_top = 0
	control_node_ref.anchor_bottom = 1
	

	# HBoxContainer setup
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0
	hbox.anchor_right = 1
	hbox.anchor_top = 0
	hbox.anchor_bottom = 1
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER


	for i in range(3):
		# VBoxContainer for each box
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Top Label
		if i == 1:
			title_label = Label.new()
			title_label.text = title
			title_label.add_theme_font_size_override("font_size", 40)
			title_label.add_theme_color_override("font_color", Color(0, 0, 0))
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		else:
			title_label = Label.new()
			title_label.text = " "
			title_label.add_theme_font_size_override("font_size", 50)
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# TextureRect with image
		var texture_rect = TextureRect.new()
		texture_rect.texture = load(images[i])
		texture_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Bottom Label
		var description_label = Label.new()
		description_label.text = descriptions[i]
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# Add nodes to vbox
		vbox.add_child(title_label)
		vbox.add_child(texture_rect)
		vbox.add_child(description_label)

		# Add vbox to hbox
		hbox.add_child(vbox)

	# Add hbox to control node and to the scene
	control_node_ref.add_child(hbox)
	$MainWindow.add_child(control_node_ref)

func generate_hint_string(answer: String):
	var answer_length = int(answer.length())
	var hint = ""
	var final_hint = ""
	var hint_string_index
	
	for letter in answer:
		hint = hint + "_"

	var number_of_hint_letters = int(answer_length / 3)
	var count = 0
	
	while count <= number_of_hint_letters:
		if count == number_of_hint_letters:
			break
		else:
			hint_string_index = randi_range(0, answer_length-1)
			hint[hint_string_index] = answer[hint_string_index]
			count += 1
	
	for letter in hint:
		final_hint = final_hint + letter
		final_hint = final_hint + "  "
	
	#debug print statements
	#print("------------")
	#print("answer_length: ",answer_length)
	#print("hint: ",hint)
	#print("final_hint: ",final_hint)
	#print("hint_string_index: ",hint_string_index)
	
	return final_hint.substr(0, final_hint.length() - 2).to_upper()

# This clears the screen of a prompt so that we can add a new one
func remove_control_node():
	if control_node_ref:
		control_node_ref.queue_free()
		control_node_ref = null

func remove_gamemode_selection():
	if control_node_ref:
		control_node_ref.queue_free()
		control_node_ref = null

func _next_prompt():
	# Get a random prompt
	#_high_round_music()
	var new_prompt = get_random_prompt(visual_prompt_dictionary, answer_list[0])
	answer_list = new_prompt[0]
	image_path = new_prompt[1]
	
	# Clear old prompt, and populate new prompt
	remove_control_node()
	create_centered_control_node()
	speech_recognizer.StartSpeechRecognition()
	$Background/Timer.play("timer")

func _game_mode_selection():
	gamemode_select = true
	remove_control_node()
	create_gamemode_selection()
	speech_recognizer.StartSpeechRecognition()

# Wait x seconds
func sleep(seconds: float) -> void:
	var timer = Timer.new()
	timer.wait_time = seconds
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

#region Sounds
######################################################################

# Sound Effects
#####################

func _success_sound():
	var audio_player = $Audio/Effects/SuccessSoundPlayer
	var sound = load("res://Audio/Effects/Correct.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _fail_sound():
	var audio_player = $Audio/Effects/SuccessSoundPlayer
	var sound = load("res://Audio/Effects/TimeUp.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _coin_sound():
	var audio_player = $Audio/Effects/CoinSoundPlayer
	var sound = load("res://Audio/Effects/Coin.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _start_sound():
	var audio_player = $Audio/Effects/StartSoundPlayer
	var sound = load("res://Audio/Effects/StartGame.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _mode_select_sound():
	var audio_player = $Audio/Effects/ModeSelectSoundPlayer
	var sound = load("res://Audio/Effects/ModeSelect.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _atmosphere_sound():
	var audio_player = $Audio/Effects/AtmosphereSoundPlayer
	var sound = load("res://Audio/Effects/Atmosphere.mp3")
	audio_player.stream = sound
	audio_player.play()
	
func _card_select_sound():
	var audio_player = $Audio/Effects/CardSelectSoundPlayer
	var sound = load("res://Audio/Effects/CardSelect.mp3")
	audio_player.stream = sound
	audio_player.play()
	
# Music
#####################
func _start_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	var sound = load("res://Audio/Music/MenuMusic.mp3")
	audio_player.stream = sound
	if sound is AudioStream:
		sound.loop = true
	audio_player.play()
	
func _stop_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	audio_player.stop()
	
func _low_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	audio_player.set_volume_db(-9.0)
	
func _high_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	audio_player.stop()
	audio_player.set_volume_db(0)

func _start_round_music():
	var audio_player = $Audio/Music/RoundMusic
	var sound = load("res://Audio/Music/RoundMusic.mp3")
	audio_player.stream = sound
	if sound is AudioStream:
		sound.loop = true
	audio_player.play()
	
func _stop_round_music():
	var audio_player = $Audio/Music/RoundMusic
	audio_player.stop()
	
func _low_round_music():
	var audio_player = $Audio/Music/RoundMusic
	audio_player.set_volume_db(-9.0)
	
func _high_round_music():
	var audio_player = $Audio/Music/RoundMusic
	audio_player.set_volume_db(0)
#endregion


func _on_mic_timer_timeout() -> void:
	print("MicTimer: reset")
	speech_recognizer.StopSpeechRecognition()
	speech_recognizer.StartSpeechRecognition()
