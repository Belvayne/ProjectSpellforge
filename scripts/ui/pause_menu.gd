extends Control

func _ready():
	self.visible = false

	# Connect button signals
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		toggle_pause()

func toggle_pause():
	visible = not visible
	get_tree().paused = visible

	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed():
	toggle_pause()  # Close the menu and resume the game

func _on_quit_pressed():
	get_tree().quit()  # Exit the game
