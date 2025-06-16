extends Node3D

@onready var health_label = $HealthLabel
@onready var health_bar = $HealthBar/Billboard
var current_health = 100
var max_health = 100

func _ready():
	update_health_display()

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

func take_damage(amount):
	current_health -= amount
	if current_health < 0:
		current_health = 0
	update_health_display()
	print("Dummy took ", amount, " damage. Health: ", current_health)

func update_health_display():
	if health_label:
		health_label.text = str(current_health) + "/" + str(max_health)
	if health_bar:
		# Update health bar color based on health percentage
		var health_percent = float(current_health) / float(max_health)
		if health_percent > 0.6:
			health_bar.modulate = Color(0, 1, 0)  # Green
		elif health_percent > 0.3:
			health_bar.modulate = Color(1, 1, 0)  # Yellow
		else:
			health_bar.modulate = Color(1, 0, 0)  # Red 