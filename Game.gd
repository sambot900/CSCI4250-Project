extends Node2D

#region Globals
######################################################################

var guess_label
var speech_recognizer
var partialResultLabel
var play_list = ["play", "hay", "pray", "why", "boy", "by", "i", "hi"]
var answer_list = ["test"]
var prompt_path
var prompt_type
var control_node_ref: Control = null
var visual_prompt_dictionary = {}
var audio_prompt_dictionary = {}
var left_to_solve_array_visual = []
var left_to_solve_array_audio = []
var guess_string = ""
var answer_string = ""
var score = 0
var prompt_counter = 0
var gamemode_list = [["one", "won", "young", "pictures", "pitchers"], ["two", "to", "too", "do", "sounds", "found"], ["three", "both", "oath", "oh", "next"]]
var gamemode = ""
var gamemode_select = false
var music1
var startmenu = true
#endregion

@onready var MusicButton = $Background/MusicButton/MusicStatus
@onready var ExitButton = $Background/ExitButton


func _ready():
	music1 = true
	# init asset visibility
	$Background/Control/CountNumber.visible = false
	$Background/StartMenuPrompt.visible = true
	$Background/Logo.visible = true
	$Background/Logo/Animal.visible = true
	$Background/Logo/Scramble.visible = true
	$Score.visible = false
	$Background/BlackScreen.visible = false
	$Background/RoundBgShadow.visible = false
	$Background/Cards.visible = false
	$Background/Cards/CardOne.visible = false
	$Background/Cards/CardTwo.visible = false
	$Background/Cards/CardThree.visible = false
	$Background/AnimateRoundOver/RoundOverText.visible = false
	$Background/AnimateRoundOver/Label.visible = false
	$Background/AnimateRoundOver/RoundOverStar.visible = false
	
	# Fill up our dictionaries with prompts (audio and visual)
	visual_prompt_dictionary["horse"] = [["horse","horses","force", "course", "or", "source", "rouse", "worse", "worse"], "res://Assets/Prompts/horse.png"]
	visual_prompt_dictionary["rabbit"] = [["rabbit", "rabbits", "reset", "radish", "rabbid", "labbit"], "res://Assets/Prompts/rabbit.png"]
	visual_prompt_dictionary["dog"] = [["dog", "hog", "dob", "da"], "res://Assets/Prompts/dog.png"]
	visual_prompt_dictionary["cat"] = [["cat", "ka", "kurt", "can", "get", "cap", "can't"], "res://Assets/Prompts/cat.png"]
	visual_prompt_dictionary["lion"] = [["lion", "i", "i'm", "why", "liar", "light", "am", "and"], "res://Assets/Prompts/lion.png"]
	visual_prompt_dictionary["panda"] = [["panda", "handa", "the", "and"], "res://Assets/Prompts/panda.png"]
	visual_prompt_dictionary["cow"] = [["cow", "cao", "go", "how"], "res://Assets/Prompts/cow.png"]
	visual_prompt_dictionary["elephant"] = [["elephant", "elegant"], "res://Assets/Prompts/elephant.png"]
	visual_prompt_dictionary["giraffe"] = [["giraffe"], "res://Assets/Prompts/giraffe.png"]
	visual_prompt_dictionary["penguin"] = [["penguin", "anglin", "hander", "on"], "res://Assets/Prompts/penguin.png"]
	visual_prompt_dictionary["eagle"] = [["eagle", "go", "you"], "res://Assets/Prompts/eagle.png"]
	visual_prompt_dictionary["alligator"] = [["alligator"], "res://Assets/Prompts/alligator.png"]
	visual_prompt_dictionary["shark"] = [["shark"], "res://Assets/Prompts/shark.png"]
	visual_prompt_dictionary["bear"] = [["bear", "bare", "there", "their"], "res://Assets/Prompts/bear.png"]
	visual_prompt_dictionary["butterfly"] = [["butterfly", "for"], "res://Assets/Prompts/butterfly.png"]
	visual_prompt_dictionary["dolphin"] = [["dolphin"], "res://Assets/Prompts/dolphin.png"]
	visual_prompt_dictionary["frog"] = [["frog"], "res://Assets/Prompts/frog.png"]
	visual_prompt_dictionary["monkey"] = [["monkey", "maki"], "res://Assets/Prompts/monkey.png"]
	visual_prompt_dictionary["koala"] = [["koala", "all"], "res://Assets/Prompts/koala.png"]
	visual_prompt_dictionary["pig"] = [["pig", "a"], "res://Assets/Prompts/pig.png"]
	visual_prompt_dictionary["snake"] = [["snake"], "res://Assets/Prompts/snake.png"]
	visual_prompt_dictionary["turtle"] = [["turtle", "total"], "res://Assets/Prompts/turtle.png"]
	visual_prompt_dictionary["tiger"] = [["tiger"], "res://Assets/Prompts/tiger.png"]
	visual_prompt_dictionary["kangaroo"] = [["kangaroo"], "res://Assets/Prompts/kangaroo.png"]

	
	audio_prompt_dictionary["cat"] = [["cat", "ka", "kurt", "can", "get", "cap", "can't"], "res://Audio/Prompts/cat1.mp3"]
	audio_prompt_dictionary["chicken"] = [["chicken","shaken"], "res://Audio/Prompts/chicken1.mp3"]
	audio_prompt_dictionary["cow"] = [["cow", "cao", "go", "how"], "res://Audio/Prompts/cow1.mp3"]
	audio_prompt_dictionary["dog"] = [["dog", "hog", "dob", "da"], "res://Audio/Prompts/dog1.mp3"]
	audio_prompt_dictionary["goat"] = [["goat", "go", "no", "doubt"], "res://Audio/Prompts/goat1.mp3"]
	audio_prompt_dictionary["hawk"] = [["hawk", "oc", "park"], "res://Audio/Prompts/hawk1.mp3"]
	audio_prompt_dictionary["horse"] = [["horse","force", "course", "or", "source", "rouse", "worse", "worse"], "res://Audio/Prompts/horse1.mp3"]
	audio_prompt_dictionary["monkey"] = [["monkey"], "res://Audio/Prompts/monkey1.mp3"]
	audio_prompt_dictionary["owl"] = [["owl","our","will","al","oh","ow", "i'll"], "res://Audio/Prompts/owl1.mp3"]
	audio_prompt_dictionary["wolf"] = [["wolf","of", "off"], "res://Audio/Prompts/wolf1.mp3"]

	# Fill up our list of unsolved prompts with animals
	refill_left_to_solve_visual()
	refill_left_to_solve_audio()
	
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


func load_texture(path: String) -> Texture2D:
	var texture = load(path)
	if texture is Texture2D:
		return texture
	else:
		push_error("Failed to load texture: " + path)
		return null

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

func _on_exit_button_pressed() -> void:
	get_tree().reload_current_scene()

func _process(_delta):
	# Label to display score is updated every tick
	$Score/StarScoreLabel.text = str(score)
	$Background/AnimateRoundOver/Label.text = str(score)

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
func refill_left_to_solve_visual():
	for key in visual_prompt_dictionary.keys():
		left_to_solve_array_visual.append(key)
	print("refill_left_to_solve_visual: REFRESHED")
	
func refill_left_to_solve_audio():
	for key in audio_prompt_dictionary.keys():
		left_to_solve_array_audio.append(key)
	
# Get random prompt from unsolved prompts
func get_random_prompt(dictionary: Dictionary, previous: String) -> Array:
	var random_key
	
	
	if dictionary == visual_prompt_dictionary:
		left_to_solve_array_visual.erase(previous)
		if left_to_solve_array_visual == []:
			refill_left_to_solve_visual()
		left_to_solve_array_visual.erase(previous)
		var keys = dictionary.keys()
		random_key = keys[randi() % keys.size()]  # Select a random key
		while random_key not in left_to_solve_array_visual:
			random_key = keys[randi() % keys.size()]
		
	elif dictionary == audio_prompt_dictionary:
		left_to_solve_array_audio.erase(previous)
		if left_to_solve_array_audio == []:
			refill_left_to_solve_audio()
		left_to_solve_array_audio.erase(previous)

		var keys = dictionary.keys()
		random_key = keys[randi() % keys.size()]  # Select a random key
		while random_key not in left_to_solve_array_audio:
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
		if last_word in play_list and startmenu:
			speech_recognizer.StopSpeechRecognition()
			guess_success(last_word)
		if last_word in answer_list:
			speech_recognizer.StopSpeechRecognition()
			guess_success(last_word)
	else:
		print("Error parsing JSON: ", json.error_string)

func start_menu_play():
	$MicTimer.stop()
	$Background/Logo/AnimateLogo.stop()
	if music1:
		_low_menu_music()
	_start_sound()
	$Background/AnimateMenuImages/AnimateMenuImagesFadeOut.play("menu_images_fade_out")
	$Background/ProceedPastStart.play("proceed_past_start")
	$Background/PromptBlink.stop()


func guess_success(answer: String):
	if answer in play_list and startmenu:
		start_menu_play()
	elif gamemode_select and answer not in play_list:
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
		if answer not in play_list:
			set_answer_label_text()
			_success_sound()
			$Background/Timer.stop()
			$Star/AnimateStar.play("star")
			if music1:
				_low_round_music()
		
#region onFinished Animations

# When proceed past start menu
func _on_proceed_past_start_animation_finished(anim_name: StringName) -> void:
	startmenu = false
	$Background/StartMenuPrompt.visible = false
	$Background/Logo.visible = false
	$Background/BlackScreen.visible = false
	#$Star.visible = false
	$Star/StarSprite.visible = false
	_game_mode_selection()

# Stop menu images animation after leaving start menu
func _on_animate_menu_images_fade_out_animation_finished(anim_name: StringName) -> void:
	$Background/AnimateMenuImages.stop()


func _on_animate_cards_animation_finished(anim_name: StringName) -> void:
	$Background/FadeOut.play("fade_out")

# Black fade "out" is finished
func _on_fade_out_animation_finished(anim_name: StringName) -> void:
	_stop_menu_music()
	$Background/FadeIn.play("fade_in_sound")
	$Score.visible = true
	#$Score/Star.visible = true
	$Score/Star.position = Vector2(85, 565)
	$Score/StarScoreLabel.visible = true
	$Background/RoundBgShadow.visible = true
	$Background/Cards.visible = false
	$Background/Cards/CardOne.visible = false
	$Background/Cards/CardTwo.visible = false
	$Background/Cards/CardThree.visible = false

# Black fade "in" is finished
func _on_fade_in_animation_finished(anim_name: StringName) -> void:
	$Background/AnimateBackground.play("round_countdown")


func stop_all_animations(node):
	if node is AnimationPlayer:
		node.stop()
	for child in node.get_children():
		stop_all_animations(child)

func end_round():
	#$Score/StarScoreLabel.visible = false
	# Stop all animations
	$Background/AnimateRoundOver/Label.text = str(score)
	stop_all_animations(get_tree().root)
	# Play the "round_over" animation
	$Background/AnimateRoundOver.play("round_over")

# A background animation is complete
func _on_animate_background_animation_finished(anim_name: StringName) -> void:
	
	# Round countdown is complete
	if anim_name == "round_countdown":
		_start_round_music()
		$MicTimer.stop()
		_next_prompt()

func _on_animate_round_over_animation_finished(anim_name: StringName) -> void:
	_game_mode_selection()
	_start_round_music()
	score = 0

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
	if prompt_type == "picture":
		texture_rect.texture = load(prompt_path)
	elif prompt_type == "sound":
		texture_rect.texture = load("res://Assets/Prompts/audio.png")
		_prompt_sound()
		
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

func prompt_gamemode_decider():
	var prompt_dictionary
	if gamemode == "picture_mode":
		prompt_type = "picture"
		return visual_prompt_dictionary
	elif gamemode == "sound_mode":
		prompt_type = "sound"
		return audio_prompt_dictionary
	elif gamemode == "mixed_mode":
		var decider = randi_range(0, 1)
		if decider == 0:
			prompt_type = "picture"
			return visual_prompt_dictionary
		else:
			prompt_type = "sound"
			return audio_prompt_dictionary
	else:
		print("prompt_gamemode_decider error")

func _next_prompt():
	# Get a random prompt
	#_high_round_music()
	prompt_counter += 1
	var prompt_dictionary = prompt_gamemode_decider()
	var new_prompt = get_random_prompt(prompt_dictionary, answer_list[0])
	answer_list = new_prompt[0]
	prompt_path = new_prompt[1]
	
	if music1:
		if prompt_type == "picture":
			_high_round_music()
		elif prompt_type == "sound":
			_low_round_music()
	
	# Clear old prompt, and populate new prompt
	remove_control_node()
	
	if prompt_counter > 9:
		end_round()
		prompt_counter = 0
	else:
		create_centered_control_node()
		speech_recognizer.StartSpeechRecognition()
		$Background/Timer.play("timer")

func _game_mode_selection():
	gamemode_select = true
	gamemode = ""
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
	
func _prompt_sound():
	var audio_player = $Audio/Effects/PromptSoundPlayer
	var sound = load(prompt_path)
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
	
func _mute_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	audio_player.set_volume_db(-80.0)
	
func _low_menu_music():
	var audio_player = $Audio/Music/MenuMusic
	audio_player.set_volume_db(-9.0)
	
func _high_menu_music():
	var audio_player = $Audio/Music/MenuMusic
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
	
func _mute_round_music():
	var audio_player = $Audio/Music/RoundMusic
	audio_player.set_volume_db(-80.0)

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


func _on_music_button_pressed() -> void:
	if music1 == true:
		music1 = false
		MusicButton.texture = load("res://Assets/UI/music_off.png")
		_mute_menu_music()
		_mute_round_music()


	elif music1 == false:
		music1 = true
		MusicButton.texture = load("res://Assets/UI/music_on.png")
		if gamemode == "":
			_high_menu_music()
		elif gamemode == "sound_mode" or gamemode == "mixed_mode":
			_low_round_music()
		else:
			_high_round_music()


func _on_animate_star_animation_finished(anim_name: StringName) -> void:
	score += 1
	_coin_sound()
	_next_prompt()
