extends Resource
class_name SingleQuestion

enum QuestionType { MULTIPLE_CHOICE, TEXT_INPUT }
enum Difficulty { NOOB, PRO }

@export var question_text: String
@export var question_type: QuestionType = QuestionType.MULTIPLE_CHOICE
@export var difficulty: Difficulty = Difficulty.NOOB

# Unified answer system
@export var answers: Array[String] = []  # All possible answers (display options for MC, accepted answers for text input)
@export var correct_answer_indices: Array[int] = []  # Which answer(s) are correct (for MC, typically just one index)

# Media
@export var media_path: String = ""
@export var media_source: String = ""

# Explanation
@export var answer_info: String = ""
