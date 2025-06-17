extends Node3D

@onready var health_label = $HealthLabel
@onready var health_bar = $HealthBar/Billboard
@onready var area = $Area3D
@onready var player_stats = $PlayerStats

func _ready():
	update_health_display()
	# Connect collision signals
	area.area_entered.connect(_on_area_entered)

func _process(_delta):
	# Make the dummy face the player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Get direction to player
		var direction = (player.global_position - global_position).normalized()
		# Only rotate on Y axis
		direction.y = 0
		if direction != Vector3.ZERO:
			# Calculate the angle to face the player
			var target_angle = atan2(direction.x, direction.z)
			# Smoothly rotate to face player
			rotation.y = lerp_angle(rotation.y, target_angle, 0.1)

func _on_area_entered(area):
	if area.is_in_group("projectile"):
		player_stats.take_damage(15)  # Base damage from projectile

func update_health_display():
	if health_label:
		health_label.text = str(player_stats.current_health) + "/" + str(player_stats.max_health)
	if health_bar:
		# Update health bar color based on health percentage
		var health_percent = float(player_stats.current_health) / float(player_stats.max_health)
		if health_percent > 0.6:
			health_bar.modulate = Color(0, 1, 0)  # Green
		elif health_percent > 0.3:
			health_bar.modulate = Color(1, 1, 0)  # Yellow
		else:
			health_bar.modulate = Color(1, 0, 0)  # Red 
