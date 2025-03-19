extends Control

func _ready() -> void:
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_hrajem_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")
	pass # Replace with function body.
