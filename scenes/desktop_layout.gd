extends Control

var question_data = preload("res://all_questions.tres")
# Variables to track the game state
var selected_questions: Array = []
var current_question_index: int = 0
var score: int = 0
var question
var answer_group
var correct_answer
var buttons: Array = []  # Array to hold button references

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize the ButtonGroup and buttons array
	answer_group = ButtonGroup.new()
	buttons = [
		$MarginContainer/HBoxContainer/VBoxContainer/GridContainer/Answer1,
		$MarginContainer/HBoxContainer/VBoxContainer/GridContainer/Answer2,
		$MarginContainer/HBoxContainer/VBoxContainer/GridContainer/Answer3,
		$MarginContainer/HBoxContainer/VBoxContainer/GridContainer/Answer4
	]
	
	# Assign buttons to the ButtonGroup
	for button in buttons:
		button.set_button_group(answer_group)

	# Update score display
	$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreNumber.text = str(score)

	# Start the game
	choose_questions()
	current_question_handling()

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
		question.correct_answer_index = question.answers.find(original_answers[question.correct_answer_index])  # Update the correct answer index
		correct_answer = "Answer" + str(question.correct_answer_index + 1)

		# Update UI
		$MarginContainer/HBoxContainer/VBoxContainer/Question.text = question.question_text
		assign_answers_to_buttons(question.answers)
	else:
		show_score()

func assign_answers_to_buttons(answers: Array[String]):
	for i in range(buttons.size()):  # Loop through all button references
		if i < answers.size():
			buttons[i].text = answers[i]  # Assign the answer to the button's text
			buttons[i].visible = true  # Ensure the button is visible
		else:
			buttons[i].visible = false  # Hide extra buttons if not needed

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
		print(pressed_button.name)
		if pressed_button.name == correct_answer:
			print("YIPEE")
			score += 1
		else:
			print("Idiot")
	else:
		print("No button selected!")

	# Update game state
	current_question_index += 1
	$MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreNumber.text = str(score)
	current_question_handling()
	unpress_all_buttons()
