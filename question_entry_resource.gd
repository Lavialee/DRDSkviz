extends Resource
class_name Question

enum QuestionType { MULTIPLE_CHOICE, TEXT_INPUT, ARRANGE}

@export var question_text: String
@export var answers: Array[String] = [] # For multiple-choice questions
@export var correct_answer_index: int = -1 # Use -1 for open-ended questions
@export var correct_answer_text: String = "" # For text-input questions
@export var question_type: QuestionType = QuestionType.MULTIPLE_CHOICE  # Dropdown menu
@export var media_path: String = ""
@export var media_source: String = ""
@export var answer_info: String = ""
