extends Control

var question_data = preload("res://all_questions.tres")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print_questions()
	pass # Replace with function body.

func print_questions():
	for i in range(50,91):
		var current_question = question_data.questions[i]  # Access the question at index i
		print("")
		if current_question.question_type == current_question.QuestionType.MULTIPLE_CHOICE:
			print("č.", i, ", multiple choice")
			print(current_question.question_text)  # Print the question text
			print(current_question.answers)
			print("správně: ", current_question.answers[current_question.correct_answer_index])
			print(current_question.answer_info)
		elif current_question.question_type == current_question.QuestionType.TEXT_INPUT:
			print("č.", i, ", text input")
			print(current_question.question_text)  # Print the question text
			print(current_question.correct_answer_text)
			print(current_question.answer_info)
		else:
			print("this is the arrange one!")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
