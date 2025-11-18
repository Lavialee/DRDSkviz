extends Control

# ============================================================================
# CONSTANTS & ENUMS
# ============================================================================

const QUESTIONS_PER_GAME = 10
const ANSWER_DELAY_SECONDS = 0.6
const AUDIO_SLIDER_STEP = 0.01

enum InputAnswerMatch {
	WRONG,
	ADEQUATE,
	CORRECT
}

@export var only_media_questions: bool = false
# ============================================================================
# NODE REFERENCES
# ============================================================================

# UI Elements
@onready var question_label = $MarginContainer/VBoxContainer/Question
@onready var answer_container = $MarginContainer/VBoxContainer/CenterContainer/AnswerContainer
@onready var center_container = $MarginContainer/VBoxContainer/CenterContainer
@onready var score_label = $HBoxContainer/ScoreNumber
@onready var confirm_label = $MarginContainer/VBoxContainer/AnswerConfirm
@onready var answer_input = $MarginContainer/VBoxContainer/AnswerInput


# Media Elements
@onready var media_container = $MarginContainer/VBoxContainer/MediaContainer
@onready var question_image = $MarginContainer/VBoxContainer/MediaContainer/Photo
@onready var audio_container = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer
@onready var no_media_picture = $MarginContainer/VBoxContainer/MediaContainer/NoMediaPicture
@onready var source_label = $MarginContainer/VBoxContainer/MediaContainer/Photo/SourceLabel


# Audio Controls
@onready var audio_streamer = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/PlayButton/Audio
@onready var slider: Slider = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/AudioTimer
@onready var play_button: TextureButton = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/PlayButton
@onready var time_label: Label = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/AudioTrackTime

# Answer Panel
@onready var answer_panel = $Answer/PanelContainer
@onready var next_question_button = $Answer/PanelContainer/VBoxContainer/NextQuestion
@onready var answer_text = $Answer/PanelContainer/VBoxContainer/TextEdit
@onready var answer_overlay = $Answer

# ============================================================================
# GAME DATA & STATE
# ============================================================================

# Resources
var question_data = preload("res://all_questions.tres")
var regular_font = preload("res://font/calibri-regular.ttf")

# Question Management
var selected_questions: Array = []
var current_question_index: int = 0
var current_question
var correct_answer_index: int = -1 # Use -1 to represent no answer

# UI State
var answer_group: ButtonGroup
var buttons: Array = []
var showing_answer: bool = false

# Audio State
var paused_position: float = 0.0
var slider_being_dragged: bool = false
var was_playing_before_drag: bool = false

# Score
var score: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_button_group()
	_setup_buttons()
	_setup_audio_slider()
	_start_game()
	
	audio_streamer.finished.connect(_on_audio_finished) # Connect the signal for when audio finishes playing
	# Set initial state
	_update_time_label()

func _setup_button_group() -> void:
	answer_group = ButtonGroup.new()
	next_question_button.pressed.connect(_next_question)

func _setup_buttons() -> void:
	buttons = [
		answer_container.get_node("Answer1"),
		answer_container.get_node("Answer2"),
		answer_container.get_node("Answer3"),
		answer_container.get_node("Answer4")
	]
	
	for button in buttons:
		button.set_button_group(answer_group)
		button.pressed.connect(func(): _on_answer_pressed(button))

func _setup_audio_slider() -> void:
	slider.min_value = 0
	slider.step = AUDIO_SLIDER_STEP
	
	slider.gui_input.connect(_on_slider_gui_input)
	slider.drag_started.connect(_on_slider_drag_started)
	slider.drag_ended.connect(_on_slider_drag_ended)

func _start_game() -> void:
	choose_questions()
	current_question_handling()

# ============================================================================
# GAME LOOP
# ============================================================================

func _process(_delta):
	if audio_streamer.playing and not slider_being_dragged:
		# If audio is playing and user isn't dragging, update the slider
		slider.value = audio_streamer.get_playback_position()
		_update_time_label()
# ============================================================================
# QUESTION MANAGEMENT
# ============================================================================
##
#func choose_questions() -> void:
	#var all_questions = question_data.questions
	##var test_question = all_questions[48]
	##all_questions.remove_at(48)
#
	#all_questions.shuffle()
	#selected_questions = all_questions.slice(0, QUESTIONS_PER_GAME)
	##selected_questions.insert(0, test_question)
	#
func choose_questions() -> void:
	var all_questions = question_data.questions

	if only_media_questions:
		# Filter only the questions that have media_path
		all_questions = all_questions.filter(
			func(q):
				return not q.media_path.is_empty()
		)
	
	all_questions.shuffle()
	selected_questions = all_questions.slice(0, QUESTIONS_PER_GAME)
func current_question_handling() -> void:
	if current_question_index >= selected_questions.size():
		show_score()
		return
	
	current_question = selected_questions[current_question_index]
	
	if _is_multiple_choice():
		_setup_multiple_choice_question()
		
	else:
		_setup_input_question()
	
	assign_answers_to_buttons(current_question.answers)
	_setup_media()
	question_label.text = current_question.question_text

func _is_multiple_choice() -> bool:
	return current_question.question_type == current_question.QuestionType.MULTIPLE_CHOICE

func _setup_multiple_choice_question() -> void:
	multiple_choice_shuffle()
	answer_input.hide()
	confirm_label.hide()
	center_container.show()


func _setup_input_question() -> void:
	answer_input.show()
	confirm_label.show()
	center_container.hide()
	

func multiple_choice_shuffle() -> void:
	var correct_text = current_question.answers[current_question.correct_answer_index]
	current_question.answers.shuffle()
	current_question.correct_answer_index = current_question.answers.find(correct_text)
	correct_answer_index = current_question.correct_answer_index # Just store the index
	print("The correct answer index is: ", correct_answer_index)

func show_new_question() -> void:
	showing_answer = false
	current_question_index += 1
	
	# Reset media visibility for new question
	media_container.show()
	no_media_picture.hide()
	question_image.hide()
	audio_container.hide()
	
	_reset_button_states()
	question_label.add_theme_font_override("font", regular_font)
	confirm_label.text = "Potvrdit odpověď!"
	
	current_question_handling()
	unpress_all_buttons()

func _reset_button_states() -> void:
	for button in buttons:
		button.add_theme_stylebox_override("disabled", load("res://shaders/disabled_neutral.tres"))
		button.disabled = false

# ============================================================================
# MEDIA MANAGEMENT
# ============================================================================

func _setup_media() -> void:
	# For image questions, the images are in the answers, not as media
	if _is_image_question():
		media_container.hide()
		return
	
	if current_question.media_path.is_empty():
		_show_no_media_placeholder()
		return
	
	media_container.show()
	no_media_picture.hide()
	
	var extension = current_question.media_path.get_extension()
	match extension:
		"png", "jpg", "jpeg":
			_load_image_media()
		"mp3", "wav":
			_load_audio_media()
		_:
			push_warning("Unsupported media format: " + extension)
			_show_no_media_placeholder()
	source_label.text = "zdroj: "+current_question.media_source


func _show_no_media_placeholder() -> void:
	no_media_picture.show()
	question_image.hide()
	audio_container.hide()

func _load_image_media() -> void:
	question_image.show()
	audio_container.hide()
	
	var image = ResourceLoader.load(current_question.media_path)
	if image:
		question_image.texture = image
	else:
		push_error("Failed to load image: " + current_question.media_path)
		_show_no_media_placeholder()

func _load_audio_media() -> void:
	question_image.hide()
	audio_container.show()
	
	var audio_resource = ResourceLoader.load(current_question.media_path)
	if audio_resource:
		audio_streamer.stream = audio_resource
		slider.max_value = audio_streamer.stream.get_length()
		_reset_audio_state()
	else:
		push_error("Failed to load audio: " + current_question.media_path)
		_show_no_media_placeholder()

func _reset_audio_state() -> void:
	if audio_streamer.playing:
		audio_streamer.stop()
	paused_position = 0.0
	slider.value = 0.0
	_update_time_label()

func _is_image_question() -> bool:
	return current_question.question_text.begins_with("Který z uvedených symbolů")


# ============================================================================
# ANSWER HANDLING
# ============================================================================

func assign_answers_to_buttons(answers: Array[String]) -> void:
	for button in buttons:
		button.hide()
		button.icon = null       # reset
		button.text = ""         # reset
	if _is_image_question():
		_assign_image_answers(answers)
	else:
		_assign_text_answers(answers)

func _assign_image_answers(answers: Array[String]) -> void:
	for i in range(min(answers.size(), buttons.size())):
		var button = buttons[i]
		button.custom_minimum_size = Vector2(170, 170)
		var path := answers[i]
		var tex := load(path)
		if tex:
			button.icon = tex
			button.text = ""           # no text
			button.expand_icon = true  # fill available space
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			push_error("Could not load image for answer: " + path)
		button.show()
	no_media_picture.hide()

func _assign_text_answers(answers: Array[String]) -> void:
	for i in range(min(answers.size(), buttons.size())):
		var button = buttons[i]
		button.custom_minimum_size = Vector2(220, 85)  # Smaller for text
		button.text = answers[i]
		button.show()
	

func show_answer(pressed_button: Button) -> void:
	_disable_all_buttons()
	
	if pressed_button == buttons[correct_answer_index]:
		_handle_correct_answer(pressed_button)
	else:
		_handle_wrong_answer(pressed_button)
	
	showing_answer = true
	_reset_audio_state()
	
	await _display_answer_info()

func _disable_all_buttons() -> void:
	for button in buttons:
		button.disabled = true

func _display_answer_info() -> void:
	if current_question.answer_info:
		await _show_answer_info()
	else:
		await get_tree().create_timer(ANSWER_DELAY_SECONDS).timeout
		show_new_question()

func _handle_correct_answer(button: Button) -> void:
	button.add_theme_stylebox_override("disabled", load("res://shaders/correct_answer.tres"))
	_increment_score()

func _handle_wrong_answer(button: Button) -> void:
	button.add_theme_stylebox_override("disabled", load("res://shaders/wrong_answer.tres"))
	_highlight_correct_button()

func _increment_score() -> void:
	score += 1
	score_label.text = str(score)

func _highlight_correct_button() -> void:
	buttons[correct_answer_index].add_theme_stylebox_override("disabled", load("res://shaders/correct_answer.tres"))

func _show_answer_info() -> void:
	answer_text.text = current_question.answer_info
	await get_tree().create_timer(ANSWER_DELAY_SECONDS).timeout
	answer_overlay.show()
	

func unpress_all_buttons() -> void:
	for button in buttons:
		button.set_pressed(false)

# ============================================================================
# INPUT ANSWER VALIDATION
# ============================================================================

func check_input_answer(expected_answer: String, actual_answer: String) -> InputAnswerMatch:
	var ts = TextServerManager.get_primary_interface()
	actual_answer = ts.strip_diacritics(actual_answer).to_lower()
	expected_answer = ts.strip_diacritics(expected_answer).to_lower()
	
	var distance = edit_distance(expected_answer, actual_answer)
	var max_distance = max(2, int(expected_answer.length() / 3.0))
	
	if expected_answer == actual_answer:
		print("The input answer is fully correct")
		return InputAnswerMatch.CORRECT
	elif distance <= max_distance:
		print("The input answer is almost correct")
		return InputAnswerMatch.ADEQUATE
	else:
		print("The input answer is wrong")
		return InputAnswerMatch.WRONG

func edit_distance(s1: String, s2: String) -> int:
	var len1 = s1.length()
	var len2 = s2.length()
	
	var dp := []
	for i in range(len1 + 1):
		dp.append([])
		for j in range(len2 + 1):
			dp[i].append(0)
	
	for i in range(len1 + 1):
		dp[i][0] = i
	for j in range(len2 + 1):
		dp[0][j] = j
	
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if s1[i - 1] == s2[j - 1] else 1
			dp[i][j] = min(
				dp[i - 1][j] + 1,
				dp[i][j - 1] + 1,
				dp[i - 1][j - 1] + cost
			)
	
	return dp[len1][len2]

# ============================================================================
# AUDIO CONTROLS
# ============================================================================

# Merges your original (working) pause logic
func _on_play_button_pressed() -> void:
	if audio_streamer.playing:
		# Is playing -> PAUSE
		paused_position = audio_streamer.get_playback_position()
		audio_streamer.stop()
		print("Pausing audio at position: ", paused_position)
	else:
		# Is paused/stopped -> PLAY from saved spot
		print("Starting/Resuming audio from position: ", paused_position)
		audio_streamer.play(paused_position)


func _on_slider_drag_started() -> void:
	slider_being_dragged = true
	# Remember if it was playing, so we can resume after dragging
	was_playing_before_drag = audio_streamer.playing
	if was_playing_before_drag:
		audio_streamer.stop() # Pause audio during drag

func _on_slider_drag_ended(_value_changed: bool) -> void:
	slider_being_dragged = false
	var seek_to = slider.value
	paused_position = seek_to # Store new position
	
	if was_playing_before_drag:
		audio_streamer.play(seek_to) # play() also seeks
	else:
		audio_streamer.seek(seek_to) # Just seek if it was paused
	
	_update_time_label() # Update label to new time


# This handles clicking on the slider bar (not dragging)
func _on_slider_gui_input(event: InputEvent) -> void:
	# Check for a left-click press that is NOT a drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if slider_being_dragged:
			return # The drag functions will handle this
		var was_playing: bool = audio_streamer.playing
		# Calculate click position and seek
		var ratio = clamp(event.position.x / slider.size.x, 0.0, 1.0)
		var new_value = ratio * slider.max_value
		
		slider.value = new_value # Move slider
		paused_position = new_value
		# Apply the cleaner logic         
		if was_playing:             
			audio_streamer.play(new_value) # play() also seeks         
		else:             
			audio_streamer.seek(new_value) # Just seek if it was paused                 
		_update_time_label() # Update label to new time


# This resets the player when the audio ends
func _on_audio_finished():
	print("Audio finished.")
	paused_position = 0.0
	slider.value = 0.0
	_update_time_label()


func _update_time_label() -> void:
	if not audio_streamer.stream:
		time_label.text = "00:00 / 00:00"
		return
	
	var current_time = 0.0
	
	# Use slider's value if dragging, otherwise use audio's position
	if slider_being_dragged:
		current_time = slider.value
	elif audio_streamer.playing:
		current_time = audio_streamer.get_playback_position()
	else:
		# When paused, use the stored position
		current_time = paused_position
	
	var total_time = audio_streamer.stream.get_length()
	time_label.text = _format_time(current_time) + " / " + _format_time(total_time)

func _format_time(seconds: float) -> String:
	var total_seconds: int = int(seconds) # or floori(seconds)
	var minutes: int = total_seconds / 60
	var secs: int = total_seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

# ============================================================================
# UI EVENT HANDLERS
# ============================================================================

func _on_answer_pressed(button: Button) -> void:
	if showing_answer:
		return
	show_answer(button)

func _on_answer_confirm_pressed() -> void:
	if showing_answer:
		show_new_question()
		return
	
	if _is_multiple_choice():
		_handle_multiple_choice_confirmation()
	else:
		await _handle_input_answer_confirmation()

func _input(event: InputEvent) -> void:
	# Check if Enter/Return key is pressed and we're in input mode (not multiple choice)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# If answer is currently being shown, move to next question
			if showing_answer:
				_next_question()
			# Only trigger input answer confirmation if input field is visible
			elif not _is_multiple_choice() and answer_input.visible:
				_on_answer_confirm_pressed()

func _handle_multiple_choice_confirmation() -> void:
	var pressed_button = answer_group.get_pressed_button()
	if pressed_button:
		show_answer(pressed_button)
	else:
		push_warning("No button selected!")

func _handle_input_answer_confirmation() -> void:
	var actual_answer = answer_input.text.strip_edges()
	if actual_answer.is_empty():
		push_warning("No answer entered!")
		return
	
	var result = check_input_answer(current_question.correct_answer_text, actual_answer)
	_update_confirm_label_for_result(result)
	
	showing_answer = true
	answer_input.clear()
	
	await _display_answer_info()

func _update_confirm_label_for_result(result: InputAnswerMatch) -> void:
	match result:
		InputAnswerMatch.CORRECT, InputAnswerMatch.ADEQUATE:
			_increment_score()
			confirm_label.text = "Správně!"
			confirm_label.add_theme_stylebox_override("disabled", load("res://shaders/wrong_answer.tres"))

		InputAnswerMatch.WRONG:
			confirm_label.text = "Špatně. Správná odpověď: " + current_question.correct_answer_text
			confirm_label.add_theme_stylebox_override("disabled", load("res://shaders/correct_answer.tres"))

func _next_question() -> void:
	show_new_question()
	answer_overlay.hide()

# ============================================================================
# GAME END
# ============================================================================

func show_score() -> void:
	media_container.hide()
	answer_input.hide()
	
	for button in buttons:
		button.hide()
	
	question_label.text = "Konec hry! Tvoje skóre: %d/%d" % [score, QUESTIONS_PER_GAME]
	
	confirm_label.show()
	confirm_label.text = "Hrát znovu"
	
	if not confirm_label.pressed.is_connected(reset_game):
		confirm_label.pressed.connect(reset_game)

func reset_game() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
