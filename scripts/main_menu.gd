extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_play_again_pressed() -> void:
	GameSettings.set_difficulty(GameSettings.Difficulty.PRO)
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")
