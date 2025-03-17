extends Control

# Quiz data structure
var current_question = {
	"question": "Which of these is a Golden Retriever?",
	"answers": [
		{
			"id": 0,
			"image_path": "res://assets/images/labrador.png",
			"text": "Labrador Retriever",
			"is_correct": false
		},
		{
			"id": 1,
			"image_path": "res://assets/images/golden.png",
			"text": "Golden Retriever",
			"is_correct": true
		},
		{
			"id": 2,
			"image_path": "res://assets/images/german_shepherd.png",
			"text": "German Shepherd",
			"is_correct": false
		},
		{
			"id": 3,
			"image_path": "res://assets/images/beagle.png",
			"text": "Beagle",
			"is_correct": false
		}
	]
}

# References to UI elements
var question_label
var answer_buttons = []
var feedback_label
var next_button

# State tracking
var selected_answer = null
var is_correct = null

func _ready():
	# Get references to nodes
	question_label = $QuestionLabel
	answer_buttons = [$AnswerGrid/Button1, $AnswerGrid/Button2, $AnswerGrid/Button3, $AnswerGrid/Button4]
	feedback_label = $FeedbackLabel
	next_button = $NextButton
	
	# Configure initial UI state
	feedback_label.hide()
	next_button.hide()
	
	# Connect the NextButton signal
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Connect all answer button signals
	for i in range(answer_buttons.size()):
		answer_buttons[i].pressed.connect(_on_answer_selected.bind(i))
	
	# Set up the current question
	setup_question()

func setup_question():
	# Reset state
	selected_answer = null
	is_correct = null
	
	# Display question
	question_label.text = current_question.question
	
	# Set up answer buttons
	for i in range(answer_buttons.size()):
		if i < current_question.answers.size():
			# Get the answer data
			var answer = current_question.answers[i]
			
			# Set up button image
			var texture = load(answer.image_path)
			answer_buttons[i].icon = texture
			
			# Set button properties
			var text_node = answer_buttons[i].get_node("Label")
			if text_node:
				text_node.text = answer.text
			
			answer_buttons[i].show()
			answer_buttons[i].disabled = false
			
			# Reset button appearance
			answer_buttons[i].modulate = Color(1, 1, 1, 1)
		else:
			# Hide unused buttons
			answer_buttons[i].hide()
	
	feedback_label.hide()
	next_button.hide()

func _on_answer_selected(answer_id):
	# Store selected answer
	selected_answer = answer_id
	
	# Check if answer is correct
	is_correct = current_question.answers[answer_id].is_correct
	
	# Change button appearances
	for i in range(answer_buttons.size()):
		if i < current_question.answers.size():
			# Disable all buttons
			answer_buttons[i].disabled = true
			
			# Change appearance based on selected answer
			if i == selected_answer:
				if is_correct:
					# Selected and correct - green
					answer_buttons[i].modulate = Color(0.5, 1, 0.5, 1)
				else:
					# Selected but incorrect - red
					answer_buttons[i].modulate = Color(1, 0.5, 0.5, 1)
			elif current_question.answers[i].is_correct and not is_correct:
				# Not selected but correct - show as correct
				answer_buttons[i].modulate = Color(0.5, 1, 0.5, 1)
			else:
				# Not selected and not correct - fade out
				answer_buttons[i].modulate = Color(1, 1, 1, 0.5)
	
	# Show feedback
	feedback_label.text = "Correct!" if is_correct else "Incorrect!"
	feedback_label.add_color_override("font_color", Color(0, 0.8, 0) if is_correct else Color(0.8, 0, 0))
	feedback_label.show()
	
	# Show next button
	next_button.show()

func _on_next_button_pressed():
	# This would load the next question in your quiz
	# For demo purposes, we just reset the current question
	setup_question()
