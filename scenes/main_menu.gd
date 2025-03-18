extends Control

func _ready() -> void:
	pass
	# Connect to window resize signal to handle responsive layout
	get_tree().get_root().size_changed.connect(_on_window_size_changed)
	# Set initial layout
	_on_window_size_changed()
	
func _on_window_size_changed():
	var window_size = get_viewport_rect().size
	var margin_container = $MarginContainer
	var vertical_box = $MarginContainer/HBoxContainer/VBoxContainer
	var play_button = $MarginContainer/HBoxContainer/VBoxContainer/Hrajem
	var how_to_button = $MarginContainer/HBoxContainer/VBoxContainer/JakHrat
	var label_font_size
	var button_font_size
	var header_font_size  # For any headers you might have
	var body_font_size
	var button_min_size
	# Check if we're on a mobile-sized screen (width < 600 pixels)
	if window_size.x < 600:
		label_font_size = 16
		button_font_size = 16
		header_font_size = 40
		body_font_size = 14
		button_min_size = Vector2(200, 40)  # Smaller buttons for mobile
		margin_container.add_theme_constant_override("margin_left", 20)
		margin_container.add_theme_constant_override("margin_right", 10)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 10)
	else:
		label_font_size = 24
		button_font_size = 20
		header_font_size = 80
		body_font_size = 18
		button_min_size = Vector2(200, 80)  # Larger buttons for desktop
		margin_container.add_theme_constant_override("margin_left", 100)
		margin_container.add_theme_constant_override("margin_right", 100)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 20)
# Apply font sizes to various elements
	play_button.add_theme_font_size_override("font_size", label_font_size)
	how_to_button.add_theme_font_size_override("font_size", label_font_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_hrajem_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DesktopLayout.tscn")
	pass # Replace with function body.
