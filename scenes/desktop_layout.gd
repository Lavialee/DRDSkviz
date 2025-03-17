extends Control

var question_data = preload("res://all_questions.tres")
var selected_questions: Array = []
var current_question_index: int = 0
var score: int = 0
var question
var answer_group
var correct_answer
var buttons: Array = []
var answer_container  # Reference to the container holding answer buttons
var showing_answer = false
var italics_font = load("res://font/calibri-italic.ttf")
var regular_font = load("res://font/calibri-regular.ttf")
func _ready() -> void:
	# Initialize the ButtonGroup
	answer_group = ButtonGroup.new()

	# Get reference to answer container
	answer_container = $MarginContainer/HBoxContainer/VBoxContainer/CenterContainer/AnswerContainer
	
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
		
	# Update score display
	$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreNumber.text = str(score)
	
	# Connect to window resize signal to handle responsive layout
	get_tree().get_root().size_changed.connect(_on_window_size_changed)	
	# Set initial layout
	_on_window_size_changed()
	
	# Start the game
	choose_questions()
	current_question_handling()

# Adjust layout based on window size
func _on_window_size_changed():
	var window_size = get_viewport_rect().size
	var question_label = $MarginContainer/HBoxContainer/VBoxContainer/Question
	var score_label: Array = [$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Score,
							$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreNumber,
							$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreOutOf]
	var confirm_label = $MarginContainer/HBoxContainer/VBoxContainer/AnswerConfirm
	var margin_container = $MarginContainer
	var vertical_box = $MarginContainer/HBoxContainer/VBoxContainer
	var label_font_size
	var button_font_size
	var header_font_size  # For any headers you might have
	var body_font_size
	var button_min_size
	# Check if we're on a mobile-sized screen (width < 600 pixels)
	if window_size.x < 600:
		answer_container.columns = 1
		label_font_size = 16
		button_font_size = 16
		header_font_size = 22
		body_font_size = 14
		button_min_size = Vector2(200, 40)  # Smaller buttons for mobile
		margin_container.add_theme_constant_override("margin_left", 20)
		margin_container.add_theme_constant_override("margin_right", 10)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 10)
		vertical_box.add_theme_constant_override("separation", 20)
	else:
		answer_container.columns = 2
		label_font_size = 24
		button_font_size = 20
		header_font_size = 30
		body_font_size = 18
		button_min_size = Vector2(200, 80)  # Larger buttons for desktop
		margin_container.add_theme_constant_override("margin_left", 100)
		margin_container.add_theme_constant_override("margin_right", 100)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 20)
		vertical_box.add_theme_constant_override("separation", 50)
# Apply font sizes to various elements
	question_label.add_theme_font_size_override("font_size", label_font_size)
	confirm_label.add_theme_font_size_override("font_size", label_font_size)
	for button in buttons:
		button.add_theme_font_size_override("font_size", button_font_size)
		button.custom_minimum_size = button_min_size
	for label in score_label:
		label.add_theme_font_size_override("font_size", button_font_size)

# Choose 10 random multiple-choice questions
func choose_questions():
	var all_questions = question_data.questions.filter(func(q):
		return q.question_type == q.QuestionType.MULTIPLE_CHOICE)
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
		
		# Update UI
		$MarginContainer/HBoxContainer/VBoxContainer/Question.text = question.question_text
		assign_answers_to_buttons(question.answers)
	else:
		show_score()

func assign_answers_to_buttons(answers: Array[String]):
	# First hide all buttons
	for button in buttons:
		button.visible = false
	
	# Show only the buttons we need
	for i in range(min(answers.size(), buttons.size())):
		buttons[i].text = answers[i]
		buttons[i].visible = true
		
	# Special case for 3 answers
	if answers.size() == 3:
		print("ted jsou 3")
		# If we're using a GridContainer with 2 columns:
		if answer_container.columns == 2:
			# For GridContainer, we can't directly set cell size overrides
			# Instead, we can use custom size flags for the third button
			buttons[2].size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# Or, place it in a custom position by reparenting
			# Move the button to be the last child so it appears centered on the bottom
			answer_container.move_child(buttons[2], answer_container.get_child_count() - 1)
	else:
		# Reset any special position for all buttons
		for button in buttons:
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
func show_score():
	# Display the final score
	$MarginContainer/HBoxContainer/VBoxContainer/Question.text = "Konec hry! Tvoje skóre: " + str(score)
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
		if showing_answer == true:
			print(pressed_button.name)
			if pressed_button.name == correct_answer:
				print("YIPEE")
				score += 1
			else:
				print("Idiot")
			current_question_index += 1
			$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreNumber.text = str(score)
			$MarginContainer/HBoxContainer/VBoxContainer/Question.add_theme_font_override("font", regular_font)
			$MarginContainer/HBoxContainer/VBoxContainer/AnswerConfirm.text = "Potvrdit odpověď!"
			current_question_handling()
			unpress_all_buttons()
		if showing_answer == false:
			$MarginContainer/HBoxContainer/VBoxContainer/Question.text = question.answer_info
			$MarginContainer/HBoxContainer/VBoxContainer/Question.add_theme_font_override("font", italics_font)
			$MarginContainer/HBoxContainer/VBoxContainer/AnswerConfirm.text = "další otázku!"
			showing_answer = true
		# Only advance if an answer was selected
	else:
		print("No button selected!")
		# Maybe show a message to the player that they need to select an answer
