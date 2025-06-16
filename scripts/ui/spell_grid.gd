extends Control

enum SpellType { GROUND_TARGET, PROJECTILE, WALL, MEDITATE }

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
@export var meditate_cooldown: float = 5.0  # Cooldown time in seconds

# Mana costs for each spell
@export var ground_target_mana_cost: float = 15.0
@export var projectile_mana_cost: float = 10.0
@export var wall_mana_cost: float = 25.0
@export var meditate_mana_cost: float = 5.0

# Spell scenes
var ground_target_spell_scene = preload("res://scenes/spells/ground_target_spell.tscn")
var wall_spell_scene = preload("res://scenes/spells/wall_spell.tscn")
var projectile_spell_scene = preload("res://scenes/spells/projectile_spell.tscn")
var meditate_spell_scene = preload("res://scenes/spells/meditate_spell.tscn")

# Spell icons
var fire_ground_icon = preload("res://Assets/spells/ground/fireFloor.png")
var ice_ground_icon = preload("res://Assets/spells/ground/iceFloor.png")
var fire_projectile_icon = preload("res://Assets/spells/projectile/fireBolt.png")
var ice_projectile_icon = preload("res://Assets/spells/projectile/iceBolt.png")
var fire_wall_icon = preload("res://Assets/spells/wall/fireWall.png")
var ice_wall_icon = preload("res://Assets/spells/wall/iceWall.png")
var meditate_icon = preload("res://Assets/spells/meditate/meditate.png")

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
var meditate_can_cast: bool = true
var ground_target_cooldown_timer: float = 0.0
var projectile_cooldown_timer: float = 0.0
var wall_cooldown_timer: float = 0.0
var meditate_cooldown_timer: float = 0.0

# Current element
var current_element = 0  # 0 for Fire, 1 for Ice

# Active meditate spell
var active_meditate_spell = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Add to group for easy access
	add_to_group("spell_grid")
	
	# Set minimum size
	custom_minimum_size = Vector2(slot_size * 2 + 10, slot_size * 2 + 10)
	
	# Set up spell slot icons
	setup_spell_slot(spell_slot1, fire_ground_icon)
	setup_spell_slot(spell_slot2, fire_projectile_icon)
	setup_spell_slot(spell_slot3, fire_wall_icon)
	setup_spell_slot(spell_slot4, meditate_icon)
	
	# Position slots in diamond pattern
	position_slots_in_diamond()
	
	# Hide spell grid by default
	hide()
	
	print("SpellGrid ready")
	print("Ground target spell scene loaded: ", ground_target_spell_scene != null)

func position_slots_in_diamond():
	# Calculate center position
	var center_x = custom_minimum_size.x / 2
	var center_y = custom_minimum_size.y / 2
	var offset = slot_size * 1 + 5  # Adjusted spacing between slots
	
	# Position slots in diamond pattern
	spell_slot1.position = Vector2(center_x, center_y - offset)  # Top
	spell_slot2.position = Vector2(center_x + offset, center_y)  # Right
	spell_slot3.position = Vector2(center_x - offset, center_y)  # Left
	spell_slot4.position = Vector2(center_x, center_y + offset)  # Bottom

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

func update_spell_icons():
	# Update icons based on current element
	spell_slot1.texture = fire_ground_icon if current_element == 0 else ice_ground_icon
	spell_slot2.texture = fire_projectile_icon if current_element == 0 else ice_projectile_icon
	spell_slot3.texture = fire_wall_icon if current_element == 0 else ice_wall_icon

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
			
	if not meditate_can_cast:
		meditate_cooldown_timer -= delta
		if meditate_cooldown_timer <= 0:
			meditate_can_cast = true
			meditate_cooldown_timer = 0
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
		spell_slot4.modulate = Color.WHITE if meditate_can_cast else slot_cooldown_color
	
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
	elif Input.is_action_just_pressed("SpellSlot4") and meditate_can_cast:
		print("SpellSlot4 pressed - Meditate spell")
		cast_meditate_spell()
	elif Input.is_action_just_released("SpellSlot4"):
		print("SpellSlot4 released - Stopping meditation")
		stop_meditation()
		
	# Check for player movement to stop meditation
	if active_meditate_spell:
		var player = get_tree().get_first_node_in_group("player")
		if player and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or 
			Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")):
			stop_meditation()

func update_slot_colors():
	spell_slot1.modulate = Color.WHITE if ground_target_can_cast else slot_cooldown_color
	spell_slot2.modulate = Color.WHITE if projectile_can_cast else slot_cooldown_color
	spell_slot3.modulate = Color.WHITE if wall_can_cast else slot_cooldown_color
	spell_slot4.modulate = Color.WHITE if meditate_can_cast else slot_cooldown_color

func cast_ground_target_spell():
	print("Starting ground target spell cast")
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
		
	var player_stats = player.get_node("PlayerStats")
	if not player_stats:
		print("PlayerStats not found!")
		return
		
	if player_stats.mana < ground_target_mana_cost:
		print("Not enough mana for ground target spell!")
		return
		
	var spell = ground_target_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate ground target spell!")
		return
		
	# Set the spell's position in front of the player
	var player_transform = player.global_transform
	var spell_position = player_transform.origin + player_transform.basis.z * -spell_distance
	spell_position.y = 0.3
	spell.global_transform.origin = spell_position
	
	# Set the spell's rotation to match player's forward direction
	spell.rotation.y = player.rotation.y
	
	# Set the spell's element
	spell.set_element(current_element)
	
	# Add the spell to the scene
	get_tree().root.add_child(spell)
	
	# Consume mana
	player_stats.use_mana(ground_target_mana_cost)
	
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
		
	# Get the player stats node
	var player_stats = player.get_node("PlayerStats")
	if not player_stats:
		print("PlayerStats not found!")
		return
		
	# Check if player has enough mana
	if player_stats.mana < projectile_mana_cost:
		print("Not enough mana for projectile spell!")
		return
		
	# Create and place the spell
	var spell = projectile_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate projectile spell!")
		return
		
	# Set the spell's position in front of the player
	var player_transform = player.global_transform
	var spell_position = player_transform.origin + player_transform.basis.z * -1.0
	spell.global_transform.origin = spell_position
	
	# Set the spell's direction to match player's forward direction
	spell.direction = -player_transform.basis.z
	
	# Set the spell's element
	spell.set_element(current_element)
	
	# Add the spell to the scene
	get_tree().root.add_child(spell)
	
	# Consume mana
	player_stats.use_mana(projectile_mana_cost)
	
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
		
	# Get the player stats node
	var player_stats = player.get_node("PlayerStats")
	if not player_stats:
		print("PlayerStats not found!")
		return
		
	# Check if player has enough mana
	if player_stats.mana < wall_mana_cost:
		print("Not enough mana for wall spell!")
		return
		
	# Create and place the spell
	var spell = wall_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate wall spell!")
		return
		
	# Set the spell's position in front of the player
	var player_transform = player.global_transform
	var spell_position = player_transform.origin + player_transform.basis.z * -spell_distance
	spell_position.y = 0  # Keep it at ground level
	spell.global_transform.origin = spell_position
	
	# Set the spell's rotation to match player's forward direction
	spell.rotation.y = player.rotation.y
	
	# Set the spell's element
	spell.set_element(current_element)
	
	# Add the spell to the scene
	get_tree().root.add_child(spell)
	
	# Consume mana
	player_stats.use_mana(wall_mana_cost)
	
	# Start cooldown
	wall_can_cast = false
	wall_cooldown_timer = wall_cooldown
	print("Wall cooldown started")

func cast_meditate_spell():
	print("Starting meditate spell cast")
	# Get the player node
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
		
	# Get the player stats node
	var player_stats = player.get_node("PlayerStats")
	if not player_stats:
		print("PlayerStats not found!")
		return
		
	# Check if player has enough mana
	if player_stats.mana < meditate_mana_cost:
		print("Not enough mana for meditate spell!")
		return
		
	# Create and place the spell
	var spell = meditate_spell_scene.instantiate()
	if not spell:
		print("Failed to instantiate meditate spell!")
		return
		
	get_tree().root.add_child(spell)
	active_meditate_spell = spell
	spell.start_meditation()
	
	# Consume mana
	player_stats.use_mana(meditate_mana_cost)
	
	# Start cooldown
	meditate_can_cast = false
	meditate_cooldown_timer = meditate_cooldown
	print("Meditate cooldown started")

func stop_meditation():
	if active_meditate_spell:
		active_meditate_spell.stop_meditation()
		active_meditate_spell.queue_free()
		active_meditate_spell = null
		print("Meditation stopped")

func set_spell_element(element: int):
	current_element = element
	update_spell_icons()  # Update icons when element changes
	print("Spell element set to: ", "Fire" if element == 0 else "Ice")
