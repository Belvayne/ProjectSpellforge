extends GridContainer

enum SpellType { GROUND_TARGET, PROJECTILE, WALL }

# References to the spell slot TextureRects
@onready var spell_slot1: TextureRect = $SpellSlot1
@onready var spell_slot2: TextureRect = $SpellSlot2
@onready var spell_slot3: TextureRect = $SpellSlot3
@onready var spell_slot4: TextureRect = $SpellSlot4

# Ground target spell settings
@export var spell_distance: float = 3.0  # Distance in front of player to place the spell
@export var ground_target_cooldown: float = 2.0  # Cooldown time in seconds
@export var projectile_cooldown: float = 1.0  # Cooldown time in seconds
@export var wall_cooldown: float = 3.0  # Cooldown time in seconds

var ground_target_spell_scene = preload("res://scenes/spells/ground_target_spell.tscn")
var wall_spell_scene = preload("res://scenes/spells/wall_spell.tscn")
var projectile_spell_scene = preload("res://scenes/spells/projectile_spell.tscn")

# Icon generator
var icon_generator = preload("res://scripts/ui/spell_icons.gd").new()

# Visual settings
@export var slot_size: int = 60  # Size of each spell slot
@export var slot_background_color: Color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray with transparency
@export var slot_border_color: Color = Color(0.4, 0.4, 0.4, 0.8)  # Lighter gray for borders
@export var slot_pressed_color: Color = Color(0.3, 0.3, 0.3, 0.8)  # Darker when pressed
@export var slot_cooldown_color: Color = Color(0.2, 0.2, 0.2, 0.4)  # Darker when on cooldown

# Cooldown tracking
var ground_target_can_cast: bool = true
var projectile_can_cast: bool = true
var wall_can_cast: bool = true
var ground_target_cooldown_timer: float = 0.0
var projectile_cooldown_timer: float = 0.0
var wall_cooldown_timer: float = 0.0

# Current element
var current_element = 0  # 0 for Fire, 1 for Ice

# Called when the node enters the scene tree for the first time.
func _ready():
	# Add to group for easy access
	add_to_group("spell_grid")
	
	# Configure grid layout
	columns = 2
	custom_minimum_size = Vector2(slot_size * 2 + 10, slot_size * 2 + 10)  # Add some padding
	add_theme_constant_override("h_separation", 5)  # Add spacing between slots
	add_theme_constant_override("v_separation", 5)
	
	# Generate spell icons
	var icons = icon_generator.generate_spell_icons()
	
	# Set up spell slot icons
	setup_spell_slot(spell_slot1, icons["ground_target"])
	setup_spell_slot(spell_slot2, icons["projectile"])
	setup_spell_slot(spell_slot3, icons["wall"])
	
	# Hide spell grid by default
	hide()
	
	print("SpellGrid ready")
	print("Ground target spell scene loaded: ", ground_target_spell_scene != null)

func setup_spell_slot(slot: TextureRect, icon: Texture2D):
	# Create background panel
	var background = Panel.new()
	background.custom_minimum_size = Vector2(slot_size, slot_size)
	background.add_theme_color_override("panel_color", slot_background_color)
	slot.add_child(background)
	background.show_behind_parent = true
	
	# Configure the icon
	slot.texture = icon
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.custom_minimum_size = Vector2(slot_size, slot_size)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add border
	var border = Panel.new()
	border.custom_minimum_size = Vector2(slot_size + 2, slot_size + 2)
	border.add_theme_color_override("panel_color", slot_border_color)
	slot.add_child(border)
	border.show_behind_parent = true
	border.position = Vector2(-1, -1)  # Offset to create border effect

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update cooldown timers
	if not ground_target_can_cast:
		ground_target_cooldown_timer -= delta
		if ground_target_cooldown_timer <= 0:
			ground_target_can_cast = true
			ground_target_cooldown_timer = 0
			update_slot_colors()
			
	if not projectile_can_cast:
		projectile_cooldown_timer -= delta
		if projectile_cooldown_timer <= 0:
			projectile_can_cast = true
			projectile_cooldown_timer = 0
			update_slot_colors()
			
	if not wall_can_cast:
		wall_cooldown_timer -= delta
		if wall_cooldown_timer <= 0:
			wall_can_cast = true
			wall_cooldown_timer = 0
			update_slot_colors()
	
	# Check for spell slot inputs and update colors
	if Input.is_action_pressed("SpellSlot1"):
		spell_slot1.modulate = slot_pressed_color
	else:
		spell_slot1.modulate = Color.WHITE if ground_target_can_cast else slot_cooldown_color
		
	if Input.is_action_pressed("SpellSlot2"):
		spell_slot2.modulate = slot_pressed_color
	else:
		spell_slot2.modulate = Color.WHITE if projectile_can_cast else slot_cooldown_color
		
	if Input.is_action_pressed("SpellSlot3"):
		spell_slot3.modulate = slot_pressed_color
	else:
		spell_slot3.modulate = Color.WHITE if wall_can_cast else slot_cooldown_color
		
	if Input.is_action_pressed("SpellSlot4"):
		spell_slot4.modulate = slot_pressed_color
	else:
		spell_slot4.modulate = Color.WHITE
	
	# Handle spell casting
	if Input.is_action_just_pressed("SpellSlot1") and ground_target_can_cast:
		print("SpellSlot1 pressed and can_cast is true")
		cast_ground_target_spell()
	elif Input.is_action_just_pressed("SpellSlot2") and projectile_can_cast:
		print("SpellSlot2 pressed - Projectile spell")
		cast_projectile_spell()
	elif Input.is_action_just_pressed("SpellSlot3") and wall_can_cast:
		print("SpellSlot3 pressed - Wall spell")
		cast_wall_spell()

func update_slot_colors():
	spell_slot1.modulate = Color.WHITE if ground_target_can_cast else slot_cooldown_color
	spell_slot2.modulate = Color.WHITE if projectile_can_cast else slot_cooldown_color
	spell_slot3.modulate = Color.WHITE if wall_can_cast else slot_cooldown_color
	spell_slot4.modulate = Color.WHITE

func cast_ground_target_spell():
	print("Starting spell cast")
	# Get the player node
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
	print("Player found at position: ", player.global_position)
		
	# Calculate position in front of player
	var spell_position = player.global_position + (-player.transform.basis.z * spell_distance)
	spell_position.y = 0.3  # DO NOT CHANGE THIS
	print("Calculated spell position: ", spell_position)
	
	# Create and place the spell
	var spell = ground_target_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate spell!")
		return
	print("Spell instantiated successfully")
	
	# Set the spell's element
	spell.element = current_element
	
	get_tree().root.add_child(spell)
	spell.global_position = spell_position
	print("Spell added to scene at position: ", spell.global_position)
	
	# Start cooldown
	ground_target_can_cast = false
	ground_target_cooldown_timer = ground_target_cooldown
	print("Ground target cooldown started")

func cast_projectile_spell():
	print("Starting projectile spell cast")
	# Get the player node
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
	print("Player found at position: ", player.global_position)
		
	# Calculate position in front of player
	var spell_position = player.global_position + (-player.transform.basis.z * spell_distance)
	spell_position.y = 2  # DO NOT CHANGE THIS
	print("Calculated spell position: ", spell_position)
	
	# Create and place the spell
	var spell = projectile_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate projectile spell!")
		return
	print("Projectile spell instantiated successfully")
	
	# Set the spell's element and direction
	spell.element = current_element
	spell.direction = -player.transform.basis.z  # Set direction to player's forward direction
	
	get_tree().root.add_child(spell)
	spell.global_position = spell_position
	print("Projectile spell added to scene at position: ", spell.global_position)
	
	# Start cooldown
	projectile_can_cast = false
	projectile_cooldown_timer = projectile_cooldown
	print("Projectile cooldown started")

func cast_wall_spell():
	print("Starting wall spell cast")
	# Get the player node
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
	print("Player found at position: ", player.global_position)
		
	# Calculate position in front of player
	var spell_position = player.global_position + (-player.transform.basis.z * spell_distance)
	spell_position.y = 0.3  # DO NOT CHANGE THIS
	print("Calculated spell position: ", spell_position)
	
	# Create and place the spell
	var spell = wall_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate wall spell!")
		return
	print("Wall spell instantiated successfully")
	
	# Set the spell's element
	spell.element = current_element
	
	get_tree().root.add_child(spell)
	spell.global_position = spell_position
	# Rotate the wall to face the player's forward direction
	spell.rotation.y = player.rotation.y
	print("Wall spell added to scene at position: ", spell.global_position)
	
	# Start cooldown
	wall_can_cast = false
	wall_cooldown_timer = wall_cooldown
	print("Wall cooldown started")

func set_spell_element(element: int):
	current_element = element
	print("Spell element set to: ", "Fire" if element == 0 else "Ice")
