extends Control

@onready var question_label = $MarginContainer/VBoxContainer/Question
@onready var answer_container = $MarginContainer/VBoxContainer/CenterContainer/AnswerContainer
@onready var score_label = $MarginContainer/HBoxContainer/ScoreNumber
@onready var confirm_label = $MarginContainer/VBoxContainer/AnswerConfirm
@onready var media_container = $MarginContainer/VBoxContainer/MediaContainer
@onready var audio_streamer = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/PlayButton/Audio
@onready var audio_timer = $MarginContainer/VBoxContainer/MediaContainer/AudioContainer/AudioTimer

var question_data = preload("res://all_questions.tres")
var italics_font = preload("res://font/calibri-italic.ttf")
var regular_font = load("res://font/calibri-regular.ttf")
var correct_answer_theme = load("res://correct_answer.tres")
var selected_questions: Array = []
var current_question_index: int = 0
var score: int = 0
var question
var answer_group
var correct_answer
var buttons: Array = []
var showing_answer = false

var paused_position = 0.0
var is_dragging_slider = false  # Track when slider is being dragged
func _ready() -> void:
	# Initialize the ButtonGroup
	answer_group = ButtonGroup.new()

	# Initialize buttons array
	buttons = [
		answer_container.get_node("Answer1"),
		answer_container.get_node("Answer2"),
		answer_container.get_node("Answer3"),
		answer_container.get_node("Answer4")
	]
	
	# Assign buttons to the ButtonGroup
	for button in buttons:
		button.set_button_group(answer_group)
	# Connect signals for the slider
	audio_timer.connect("drag_started", _on_audio_timer_drag_started)
	audio_timer.connect("drag_ended", _on_audio_timer_drag_ended)
	
	# Start the game
	choose_questions()
	current_question_handling()

func _process(delta):
# Only update slider position when not being dragged
	if audio_streamer.stream and audio_streamer.playing and not is_dragging_slider:
		audio_timer.value = audio_streamer.get_playback_position()

# Choose 10 random multiple-choice questions
func choose_questions():
	var all_questions = question_data.questions.filter(func(q):
		return q.question_type == q.QuestionType.MULTIPLE_CHOICE && q.media_path)
	all_questions.shuffle()
	selected_questions = all_questions.slice(0, 10)  # Select the first 10 elements

# Take shuffled questions, handle shuffling answers
func current_question_handling():
	if current_question_index < selected_questions.size():
		question = selected_questions[current_question_index]
		var original_answers = question.answers.duplicate()  # Make a copy of the original answers
		question.answers.shuffle()  # Shuffle the answers
		question.correct_answer_index = question.answers.find(original_answers[question.correct_answer_index])  # Update correct index
		correct_answer = "Answer" + str(question.correct_answer_index + 1)
		print("the correct answer is: ",correct_answer)
		var file_extension = question.media_path.get_extension()
		if question.media_path:
			match file_extension:
				"png","jpg","jpeg": 
					print("this is a picture")
					$MarginContainer/VBoxContainer/MediaContainer/Photo.set_visible(true)
					$MarginContainer/VBoxContainer/MediaContainer/AudioContainer.set_visible(false)
					$MarginContainer/VBoxContainer/MediaContainer/Photo.texture = load(question.media_path)
				"mp3","wav": 
					print("this is a mp3")
					$MarginContainer/VBoxContainer/MediaContainer/AudioContainer.set_visible(true)
					$MarginContainer/VBoxContainer/MediaContainer/Photo.set_visible(false)

					# Load the audio stream
					var audio_resource = load(question.media_path)
					audio_streamer.stream = audio_resource

					# Set up slider max value after ensuring the stream is loaded
					if audio_streamer.stream != null:
						var audio_length = audio_streamer.stream.get_length()
						print("Audio length: ", audio_length)
						$MarginContainer/VBoxContainer/MediaContainer/AudioContainer/AudioTimer.max_value = audio_length
					else:
						print("Warning: Audio stream failed to load")
			print("has media! ", question.media_path)
			print("this should be the extension: ", file_extension)
		else:
			media_container.set_visible(false)
		# Update UI
		question_label.text = question.question_text
		assign_answers_to_buttons(question.answers)
	else:
		media_container.set_visible(false)
		show_score()

func assign_answers_to_buttons(answers: Array[String]):
	# First hide all buttons
	for button in buttons:
		button.visible = false

	# Show only the buttons we need
	for i in range(min(answers.size(), buttons.size())):
		buttons[i].text = answers[i]
		buttons[i].visible = true

func show_score():
	# Display the final score
	question_label.text = "Konec hry! Tvoje skóre: " + str(score)

	for button in buttons:
		button.visible = false  # Hide all answer buttons

func unpress_all_buttons():
	for button in buttons:
		if button is Button:
			button.set_pressed(false)  # Use set_pressed to unpress the button

# Called when the confirm button is pressed
func _on_answer_confirm_pressed() -> void:
	var pressed_button = answer_group.get_pressed_button()
	if pressed_button:
		if showing_answer:
			showing_answer = false
			current_question_index += 1
			for button in buttons:
				button.add_theme_stylebox_override("disabled",  load("res://disabled_neutral.tres"))
				button.disabled = false
				print("buttons NOT disabled")
				pass #vrátit look
			question_label.add_theme_font_override("font", regular_font)
			confirm_label.text = "Potvrdit odpověď!"
			current_question_handling()
			unpress_all_buttons()

		else:
			for button in buttons:
				button.disabled = true
				print("buttons disabled")
			print("The pressed answer: ", pressed_button.name)

			if pressed_button.name == correct_answer:
				pressed_button.add_theme_stylebox_override("disabled",  load("res://correct_answer.tres"))
				print("Chose the correct answer!")
				score += 1
				score_label.text = str(score)

			else:
				print("Chose a wrong answer!")
				pressed_button.add_theme_stylebox_override("disabled",  load("res://wrong_answer.tres"))
				var correct_button =  str("MarginContainer/VBoxContainer/CenterContainer/AnswerContainer/%s" % correct_answer)
				print(correct_button)
				get_node(correct_button).add_theme_stylebox_override("disabled",  load("res://correct_answer.tres"))

			showing_answer = true
			question_label.text = question.answer_info
			question_label.add_theme_font_override("font", italics_font)
			confirm_label.text = "Další otázku!"
			print("Showing answer? ",showing_answer)
		# Only advance if an answer was selected
	else:
		print("No button selected!")
		# Maybe show a message to the player that they need to select an answer


func _on_play_button_pressed() -> void:
	print("Audio stream exists: ", audio_streamer.stream != null)
	print("Current audio position: ", audio_streamer.get_playback_position())
	print("Audio playing state before: ", audio_streamer.playing)

	if audio_streamer.playing:
		# Pause audio and save position
		paused_position = audio_streamer.get_playback_position()
		audio_streamer.stream_paused = true
		print("Pausing audio at position: ", paused_position)
	else:
# If it's not playing at all (first play), start it
		if !audio_streamer.playing and paused_position == 0.0:
			print("Starting audio from beginning")
			audio_streamer.play()
		else:
			# Resume from saved position
			print("Resuming audio from position: ", paused_position)
			audio_streamer.stream_paused = false
	print("Audio playing state after: ", audio_streamer.playing)
	print("Audio paused state after: ", audio_streamer.stream_paused)

# Only seek audio when user is manually changing the slider
func _on_audio_timer_value_changed(value: float) -> void:
	if is_dragging_slider:
		audio_streamer.seek(value)

# Track when slider dragging starts
func _on_audio_timer_drag_started() -> void:
	is_dragging_slider = true
	# Optionally pause audio while dragging
	if audio_streamer.playing:
		audio_streamer.stream_paused = true

# Track when slider dragging ends
func _on_audio_timer_drag_ended(value_changed: bool) -> void:
	is_dragging_slider = false
	# Resume audio if it was playing
	if audio_streamer.playing:
		audio_streamer.stream_paused = false
