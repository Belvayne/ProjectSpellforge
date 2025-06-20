extends Node3D

enum Element { FIRE, ICE }

@export var base_damage: int = 10  # Base damage before scaling
@export var tick_rate: float = 1.0  # Time between damage ticks
@export var wall_size: Vector3 = Vector3(3, 4, 0.2)  # Default size of the wall (width, height, thickness)
@export var burn_ticks: int = 3  # Number of burn ticks
@export var stack_time: float = 3.0  # Time before applying another stack
@export var lifetime: float = 5.0  # Time before spell despawns
@export var element: Element = Element.FIRE  # Current element type

var spellpower: float = 1.0  # Will be set if connected to player stats
var active = true
var current_burn_target = null
var burn_stacks = 0
var max_burn_stacks = 2
var stack_timer = 0.0
var despawn_timer = 0.0

func _ready():
	# Set size dynamically
	$MeshInstance3D.scale = wall_size
	$Area3D/CollisionShape3D.shape.extents = wall_size / 2  # Adjust collision shape
	
	# Set material color based on element
	update_element_visuals()
	
	# Connect signals
	$Area3D.body_entered.connect(_on_area_3d_body_entered)
	$Area3D.body_exited.connect(_on_area_3d_body_exited)
	$Area3D.area_entered.connect(_on_area_3d_area_entered)
	
	# Add StaticBody3D for ice walls
	if element == Element.ICE:
		var static_body = StaticBody3D.new()
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.extents = wall_size / 2
		static_body.add_child(collision_shape)
		add_child(static_body)

func set_element(new_element: int) -> void:
	element = new_element
	update_element_visuals()
	
	# Add or remove StaticBody3D based on element
	if element == Element.ICE:
		if not has_node("StaticBody3D"):
			var static_body = StaticBody3D.new()
			var collision_shape = CollisionShape3D.new()
			collision_shape.shape = BoxShape3D.new()
			collision_shape.shape.extents = wall_size / 2
			static_body.add_child(collision_shape)
			add_child(static_body)
	else:
		if has_node("StaticBody3D"):
			$StaticBody3D.queue_free()

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
		queue_free()  # Remove the spell from the scene

func _on_area_3d_body_entered(body):
	if body.has_node("PlayerStats") and active and element == Element.FIRE:
		current_burn_target = body.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)

func _on_area_3d_body_exited(body):
	if body.has_node("PlayerStats") and element == Element.FIRE:
		current_burn_target = null
		stack_timer = 0.0
		burn_stacks = 0

func _on_area_3d_area_entered(area):
	# Check if the area belongs to a player or enemy
	var parent = area.get_parent()
	if parent.has_node("PlayerStats") and active and element == Element.FIRE:
		current_burn_target = parent.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)

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
