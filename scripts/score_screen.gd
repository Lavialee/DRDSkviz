extends Control

@onready var score_label = $MarginContainer/AspectRatioContainer/VBoxContainer/VBoxContainer/PlayAgain # Adjust path to your Label node

func _ready() -> void:
	# Add all persistent nodes to the back (from desktop_layout.gd logic)
	for node in GameSettings.persistent_nodes:
		if node:
			add_child(node)
			move_child(node, 0) # Move each to the back
	
	# Get the score from GameSettings and display it
	var score = GameSettings.get_score() 
	var max_score = GameSettings.get_max_score()
	
	score_label.text = "Tvoje skóre: %d/%d" % [score, max_score]
	
func _process(_delta: float) -> void:
	pass

# For "Play Again" button
func _on_play_again_pressed() -> void:
	_remove_persistent_nodes()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _remove_persistent_nodes() -> void:
	for node in GameSettings.persistent_nodes:
		if node and node.get_parent():
			remove_child(node)
