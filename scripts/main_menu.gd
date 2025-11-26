extends Control

func _ready() -> void:
	# Cache all nodes you want to persist
	GameSettings.persistent_nodes = [
		$Background,
		$Gradient,  # Add as many as you need
		# $YetAnotherNode,
	]

func _process(_delta: float) -> void:
	pass

# For "Noob" difficulty button
func _on_noob_pressed() -> void:
	_remove_persistent_nodes()
	GameSettings.set_difficulty(GameSettings.Difficulty.NOOB)
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")

# For "Pro" difficulty button
func _on_pro_pressed() -> void:
	_remove_persistent_nodes()
	GameSettings.set_difficulty(GameSettings.Difficulty.PRO)
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")

func _remove_persistent_nodes() -> void:
	for node in GameSettings.persistent_nodes:
		if node and node.get_parent():
			remove_child(node)
