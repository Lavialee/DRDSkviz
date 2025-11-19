extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

# For "Noob" difficulty button
func _on_noob_pressed() -> void:
	GameSettings.set_difficulty(GameSettings.Difficulty.NOOB)
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")

# For "Pro" difficulty button
func _on_pro_pressed() -> void:
	GameSettings.set_difficulty(GameSettings.Difficulty.PRO)
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")
