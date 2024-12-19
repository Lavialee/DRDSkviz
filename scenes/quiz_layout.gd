extends Control

var phone_layout: VBoxContainer
var desktop_layout: GridContainer
var buttons: Array  # Array to store the button nodes

func _ready():
	# Get references to the containers
	phone_layout = $VBoxContainer
	desktop_layout = $GridContainer
	
	# Gather all buttons (assuming they're direct children of Control)
	buttons = [
		$Answer1,
		$Answer2,
		$Answer3,
		$Answer4,
	]
	
	adjust_layout()  # Set layout on startup
	get_window().connect("size_changed", Callable(self, "_on_window_size_changed"))

func _on_window_size_changed():
	adjust_layout()

func adjust_layout():
	var window_size = get_window().size.x  # Screen width
	if window_size < 800:  # Phone threshold
		reparent_buttons(phone_layout)
	else:  # Desktop threshold
		reparent_buttons(desktop_layout)

func reparent_buttons(target_container):
	for button in buttons:
		# Remove the button from its current parent
		if button.get_parent() != target_container:
			button.get_parent().remove_child(button)
			# Add the button to the target container
			target_container.add_child(button)
