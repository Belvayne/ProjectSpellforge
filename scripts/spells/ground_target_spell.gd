extends Node3D

enum Element { FIRE, ICE }

@export var base_damage: int = 10  # Base damage before scaling
@export var tick_rate: float = 1.0  # Time between damage ticks
@export var area_size: Vector3 = Vector3(3, 0.1, 3)  # Default size of the area (width, height, depth)
@export var burn_ticks: int = 3  # Number of burn ticks
@export var stack_time: float = 3.0  # Time before applying another stack
@export var lifetime: float = 5.0  # Time before spell despawns
@export var element: Element = Element.FIRE  # Current element type
@export var ice_speed_multiplier: float = 2.0  # Speed multiplier for ice floors (higher = more sliding)

var spellpower: float = 1.0  # Will be set if connected to player stats
var active = true
var current_burn_target = null
var burn_stacks = 0
var max_burn_stacks = 2
var stack_timer = 0.0
var despawn_timer = 0.0
var affected_players = {}  # Dictionary to track players affected by ice and their original speeds

func _ready():
	# Set size dynamically
	$MeshInstance3D.scale = area_size
	
	# Create Area3D if it doesn't exist
	if not has_node("Area3D"):
		var area = Area3D.new()
		add_child(area)
		area.name = "Area3D"
	
	# Create CollisionShape3D if it doesn't exist
	if not $Area3D.has_node("CollisionShape3D"):
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.extents = area_size / 2
		$Area3D.add_child(collision_shape)
		collision_shape.name = "CollisionShape3D"
	
	# Set material color based on element
	update_element_visuals()
	
	# Connect signals
	$Area3D.body_entered.connect(_on_area_3d_body_entered)
	$Area3D.body_exited.connect(_on_area_3d_body_exited)
	$Area3D.area_entered.connect(_on_area_3d_area_entered)

func set_element(new_element: int) -> void:
	element = new_element
	update_element_visuals()

func update_element_visuals() -> void:
	var material = $MeshInstance3D.mesh.surface_get_material(0).duplicate()
	match element:
		Element.FIRE:
			material.albedo_color = Color(0.8, 0.2, 0.2)  # Red for fire
		Element.ICE:
			material.albedo_color = Color(0.2, 0.6, 0.8)  # Blue for ice
	$MeshInstance3D.material_override = material

func _process(delta):
	if current_burn_target and active and element == Element.FIRE:
		stack_timer += delta
		if stack_timer >= stack_time and burn_stacks < max_burn_stacks:
			apply_element_effect(current_burn_target)
			stack_timer = 0.0
	
	# Handle despawn timer
	despawn_timer += delta
	if despawn_timer >= lifetime:
		# Restore original speeds for any affected players
		for player_data in affected_players.values():
			if is_instance_valid(player_data.player):
				player_data.player.speed = player_data.original_speed
				player_data.player.sprint_speed = player_data.original_sprint_speed
		queue_free()  # Remove the spell from the scene

func _on_area_3d_body_entered(body):
	if element == Element.FIRE and body.has_node("PlayerStats") and active:
		current_burn_target = body.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)
	elif element == Element.ICE and body is CharacterBody3D:
		if not affected_players.has(body):
			# Store original speeds
			affected_players[body] = {
				"player": body,
				"original_speed": body.speed,
				"original_sprint_speed": body.sprint_speed
			}
			# Apply speed multiplier
			body.speed *= ice_speed_multiplier
			body.sprint_speed *= ice_speed_multiplier
			print("Player entered ice area - increased speed")

func _on_area_3d_body_exited(body):
	if element == Element.FIRE and body.has_node("PlayerStats"):
		current_burn_target = null
		stack_timer = 0.0
		burn_stacks = 0
	elif element == Element.ICE and body is CharacterBody3D:
		if affected_players.has(body):
			var player_data = affected_players[body]
			# Restore original speeds
			body.speed = player_data.original_speed
			body.sprint_speed = player_data.original_sprint_speed
			affected_players.erase(body)
			print("Player exited ice area - restored speed")

func _on_area_3d_area_entered(area):
	# Check if the area belongs to a player or enemy
	var parent = area.get_parent()
	if element == Element.FIRE and parent.has_node("PlayerStats") and active:
		current_burn_target = parent.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)
	elif element == Element.ICE and parent is CharacterBody3D:
		if not affected_players.has(parent):
			# Store original speeds
			affected_players[parent] = {
				"player": parent,
				"original_speed": parent.speed,
				"original_sprint_speed": parent.sprint_speed
			}
			# Apply speed multiplier
			parent.speed *= ice_speed_multiplier
			parent.sprint_speed *= ice_speed_multiplier
			print("Player entered ice area - increased speed")

func apply_element_effect(player_stats):
	burn_stacks += 1
	print("Applying element effect stack ", burn_stacks)
	
	var effect_damage = (base_damage * spellpower) * 0.5  # Effect for half the original damage
	
	# Start a new concurrent effect
	apply_element_ticks(player_stats, effect_damage)

func apply_element_ticks(player_stats, effect_damage):
	for i in range(burn_ticks):
		if player_stats.is_inside_tree():
			player_stats.take_damage(effect_damage)
			match element:
				Element.FIRE:
					print("Fire tick ", i + 1, " of ", burn_ticks, " (Stack ", burn_stacks, ")")
				Element.ICE:
					print("Ice tick ", i + 1, " of ", burn_ticks, " (Stack ", burn_stacks, ")")
			await get_tree().create_timer(tick_rate).timeout
