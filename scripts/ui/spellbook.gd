extends Control

@onready var spell_grid = $SpellGrid
@onready var fire_button = $VBoxContainer/FireButton
@onready var ice_button = $VBoxContainer/IceButton

# Colors for button states
var selected_color = Color(0.8, 0.8, 0.8)  # Light gray for selected
var normal_color = Color(1, 1, 1)  # White for unselected

func _ready():
	# Connect button signals
	fire_button.pressed.connect(_on_fire_pressed)
	ice_button.pressed.connect(_on_ice_pressed)
	
	# Hide spellbook by default
	hide()
	
	# Set initial button states
	update_button_states(0)  # Start with Fire selected
	
	# Debug print to check if spell grid is found
	if spell_grid:
		print("Spell grid found successfully")
	else:
		print("Failed to find spell grid!")
		# Try to find the spell grid using a different method
		spell_grid = get_tree().get_first_node_in_group("spell_grid")
		if spell_grid:
			print("Found spell grid through group")
		else:
			print("Still couldn't find spell grid")
			# Print the scene tree for debugging
			print("Current scene tree:")
			print_tree()

func _input(event):
	if event.is_action_pressed("Spellbook"):
		if visible:
			close_spellbook()
		else:
			open_spellbook()
	elif event.is_action_pressed("ui_cancel") and visible:
		close_spellbook()
		get_viewport().set_input_as_handled()

func open_spellbook():
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_spellbook():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_button_states(selected_element: int):
	# Reset all buttons to normal state
	fire_button.modulate = normal_color
	ice_button.modulate = normal_color
	
	# Set selected button
	match selected_element:
		0:  # Fire
			fire_button.modulate = selected_color
		1:  # Ice
			ice_button.modulate = selected_color

func _on_fire_pressed():
	print("Fire button pressed")
	if spell_grid:
		print("Calling set_spell_element with Fire")
		spell_grid.set_spell_element(0)  # 0 for Fire
		update_button_states(0)
		print("Selected Fire element")
	else:
		print("Spell grid is null when trying to set Fire element")

func _on_ice_pressed():
	print("Ice button pressed")
	if spell_grid:
		print("Calling set_spell_element with Ice")
		spell_grid.set_spell_element(1)  # 1 for Ice
		update_button_states(1)
		print("Selected Ice element")
	else:
		print("Spell grid is null when trying to set Ice element") 