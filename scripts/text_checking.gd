extends Node
var question_data = preload("res://all_questions.tres")
var selected_questions: Array = []

var test_cases = [
	["ano", "ano", true],
	["test case", "test csae", true], 
	["Case Test", "caSe tEst", true], 
	["ódpověď", "odpoved", true],
	["Tohle je správná odpověď","Vymýšlím si věci", false],
	["Tohle je správná odpověď","Tohle ej správná opdoved", true],
	["odpoved", "answer", false]
	]
func choose_questions() -> void: 
	var all_questions = question_data.questions.filter(func(q):
		return q.question_type == q.QuestionType.TEXT_INPUT) 
	all_questions.shuffle()
	selected_questions = all_questions.slice(0, 10)  # Select the first 10 elements
	print(selected_questions[0].question_text)


func _ready() -> void:
	choose_questions()
	run_tests()


func check_answer(expected_answer:String, actual_answer:String) -> bool:
	var ts = TextServerManager.get_primary_interface()
	actual_answer = ts.strip_diacritics(actual_answer)
	expected_answer = ts.strip_diacritics(expected_answer)
	actual_answer = actual_answer.to_lower()
	expected_answer = expected_answer.to_lower()
	var distance = edit_distance(expected_answer, actual_answer)
	if distance > max(2, int(expected_answer.length() / 3)):
		return false
	else:
		return true

func edit_distance(s1: String, s2: String) -> int:
	var len1 = s1.length()
	var len2 = s2.length()

	# Create a 2D array (len1+1 x len2+1) initialized with zeros
	var dp := []
	for i in range(len1 + 1):
		dp.append([])
		for j in range(len2 + 1):
			dp[i].append(0)
	
	# Initialize base cases
	for i in range(len1 + 1):
		dp[i][0] = i
	for j in range(len2 + 1):
		dp[0][j] = j
	
	# Fill the matrix
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if s1[i - 1] == s2[j - 1] else 1
			dp[i][j] = min(
				dp[i - 1][j] + 1,      # Deletion
				dp[i][j - 1] + 1,      # Insertion
				dp[i - 1][j - 1] + cost  # Substitution
			)
	return dp[len1][len2]


func run_tests():
	for case in test_cases:
		if case[2] == check_answer(case[0],case[1]):
			print(case, "\n - does what expected")
		else:
			print(case, "\n - !!! somethings wrong!")
	pass
