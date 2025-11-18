extends Node

# Difficulty levels
enum Difficulty {
	NOOB = 0,
	PRO = 1
}

# Default difficulty
var selected_difficulty: int = Difficulty.NOOB

func set_difficulty(difficulty: int) -> void:
	selected_difficulty = difficulty
	print("Difficulty set to: ", "NOOB" if difficulty == Difficulty.NOOB else "PRO")

func get_difficulty() -> int:
	return selected_difficulty
