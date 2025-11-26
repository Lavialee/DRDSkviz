extends Control

@onready var score_label = $MarginContainer/AspectRatioContainer/VBoxContainer/VBoxContainer/PlayAgain # Adjust path to your Label node

func _ready() -> void:
	# Get the score from GameSettings and display it
	var score = GameSettings.get_score()
	var max_score = GameSettings.get_max_score()
	
	score_label.text = "Tvoje skóre: %d/%d" % [score, max_score]

func _process(_delta: float) -> void:
	pass

# For "Play Again" button
func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
