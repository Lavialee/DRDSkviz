extends Node

# Difficulty levels
enum Difficulty {
	NOOB = 0,
	PRO = 1
}

var selected_difficulty: int = Difficulty.NOOB
var current_score: int = 0
var max_score: int = 0

# Store multiple persistent nodes
var persistent_nodes: Array[Node] = []

func set_difficulty(difficulty: int) -> void:
	selected_difficulty = difficulty
	print("Difficulty set to: ", "NOOB" if difficulty == Difficulty.NOOB else "PRO")

func get_difficulty() -> int:
	return selected_difficulty

func set_score(score: int, max: int) -> void:
	current_score = score
	max_score = max

func get_score() -> int:
	return current_score

func get_max_score() -> int:
	return max_score
