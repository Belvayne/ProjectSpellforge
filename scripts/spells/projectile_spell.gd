extends Node3D

enum Element { FIRE, ICE }

@export var base_damage: int = 15  # Base damage before scaling
@export var projectile_speed: float = 20.0  # Speed of the projectile
@export var projectile_size: float = 0.5  # Size of the projectile
@export var burn_ticks: int = 3  # Number of burn ticks
@export var tick_rate: float = 1.0  # Time between damage ticks
@export var stack_time: float = 3.0  # Time before applying another stack
@export var lifetime: float = 3.0  # Time before spell despawns
@export var element: Element = Element.FIRE  # Current element type

var spellpower: float = 1.0  # Will be set if connected to player stats
var active = true
var current_burn_target = null
var burn_stacks = 0
var max_burn_stacks = 2
var stack_timer = 0.0
var despawn_timer = 0.0
var direction = Vector3.FORWARD  # Will be set when spawned

func _ready():
	# Add to projectile group
	add_to_group("projectile")
	
	# Set size dynamically
	$MeshInstance3D.scale = Vector3(projectile_size, projectile_size, projectile_size)
	$MeshInstance3D/Area3D/CollisionShape3D.shape.radius = projectile_size
	
	# Set material color based on element
	update_element_visuals()
	
	# Connect signals
	$MeshInstance3D/Area3D.body_entered.connect(_on_area_3d_body_entered)
	$MeshInstance3D/Area3D.body_exited.connect(_on_area_3d_body_exited)
	$MeshInstance3D/Area3D.area_entered.connect(_on_area_3d_area_entered)

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
	# Move the projectile
	position += direction * projectile_speed * delta
	
	# Handle burn stacks
	if current_burn_target and active:
		stack_timer += delta
		if stack_timer >= stack_time and burn_stacks < max_burn_stacks:
			apply_element_effect(current_burn_target)
			stack_timer = 0.0
	
	# Handle despawn timer
	despawn_timer += delta
	if despawn_timer >= lifetime:
		queue_free()  # Remove the spell from the scene

func _on_area_3d_area_entered(area):
	# Destroy the projectile on any collision
	queue_free()
	
	# Check if the area belongs to a player or enemy
	var parent = area.get_parent()
	if parent.has_node("PlayerStats") and active:
		current_burn_target = parent.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)

func _on_area_3d_body_entered(body):
	# Destroy the projectile on any collision
	queue_free()
	
	# Check if the body has PlayerStats
	if body.has_node("PlayerStats") and active:
		current_burn_target = body.get_node("PlayerStats")
		stack_timer = 0.0
		# Apply initial damage
		var initial_damage = base_damage * spellpower
		current_burn_target.take_damage(initial_damage)
		print("Initial damage: ", initial_damage)
		# Start first element effect
		apply_element_effect(current_burn_target)

func _on_area_3d_body_exited(body):
	if body.has_node("PlayerStats"):
		current_burn_target = null
		stack_timer = 0.0
		burn_stacks = 0

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
