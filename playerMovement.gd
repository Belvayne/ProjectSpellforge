extends CharacterBody3D

# Base movement speed for walking/running
const SPEED = 5.0
# Vertical force applied when jumping
const JUMP_VELOCITY = 4.5
# Speed at which the character moves during a dodge
const DODGE_SPEED = 50.0
# How long the dodge action lasts in seconds
const DODGE_DURATION = 0.15
# Time that must pass after a dodge before another can be performed
const DODGE_COOLDOWN = 0.05
# Maximum time between two taps to register as a double-tap (in seconds)
const DOUBLE_TAP_WINDOW = 0.2

# Distance-based dodge control
# Total distance the dodge will cover in units
const DODGE_DISTANCE = 5.0
# How quickly the character reaches dodge speed (currently unused)
const DODGE_ACCELERATION = 100.0

# Camera control settings
# Multiplier for mouse movement to camera rotation
const MOUSE_SENSITIVITY = 0.002
# Lowest angle the camera can look (negative is up)
const CAMERA_MIN_ANGLE = -80.0
# Highest angle the camera can look (positive is down)
const CAMERA_MAX_ANGLE = 80.0

# Dodge mechanics variables
# Stores the last time each movement key was pressed for double-tap detection
var last_tap_time = {
	"ui_left": 0,
	"ui_right": 0,
	"ui_up": 0,
	"ui_down": 0
}
# True while performing a dodge action
var is_dodging = false
# Counts down during dodge action, when reaches 0 dodge ends
var dodge_timer = 0.0
# Normalized vector storing the current dodge direction
var dodge_direction = Vector3.ZERO
# Whether the player is allowed to perform a dodge
var can_dodge = true
# Counts down after dodge, prevents dodge spam
var dodge_cooldown_timer = 0.0
# Tracks how far the dodge has left to travel
var remaining_dodge_distance: float = 0.0

# Node references (automatically assigned when scene loads)
# SpringArm3D node that controls camera distance and collision
@onready var spring_arm: SpringArm3D = $SpringArm3D
# Main camera node attached to spring arm
@onready var camera: Camera3D = $SpringArm3D/Camera3D
# Reference to the player stats node for managing stamina
@onready var stats = $PlayerStats

# Add these with the other constants at the top
# Speed multiplier when sprinting
const SPRINT_SPEED_MULTIPLIER = 2.0
# How quickly to transition to/from sprint speed
const SPRINT_ACCELERATION = 10.0

# Add these with the other variables
# Tracks if the player is currently sprinting
var is_sprinting = false
# Current speed multiplier (for smooth sprint transition)
var current_speed_multiplier = 1.0

func _ready():
	# Capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate the spring arm for looking up/down
		spring_arm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, 
			deg_to_rad(CAMERA_MIN_ANGLE), 
			deg_to_rad(CAMERA_MAX_ANGLE))
		
		# Rotate the player for looking left/right
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle dodge cooldown
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			can_dodge = true

	# Handle active dodge
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
		else:
			# Calculate how far to move this frame
			var move_distance = DODGE_SPEED * delta
			remaining_dodge_distance -= move_distance
			
			if remaining_dodge_distance <= 0:
				is_dodging = false
			else:
				velocity.x = dodge_direction.x * DODGE_SPEED
				velocity.z = dodge_direction.z * DODGE_SPEED
				move_and_slide()
				return

	# Get the input direction relative to camera orientation
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3.ZERO
	
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Check for double taps
	check_dodge("ui_left", Vector3.LEFT)
	check_dodge("ui_right", Vector3.RIGHT)
	check_dodge("ui_up", Vector3.FORWARD)
	check_dodge("ui_down", Vector3.BACK)

	# Normal movement
	if direction:
		# Check for sprint input
		if Input.is_action_pressed("sprint") and is_on_floor():
			is_sprinting = true
			current_speed_multiplier = move_toward(current_speed_multiplier, SPRINT_SPEED_MULTIPLIER, SPRINT_ACCELERATION * delta)
		else:
			is_sprinting = false
			current_speed_multiplier = move_toward(current_speed_multiplier, 1.0, SPRINT_ACCELERATION * delta)
		
		# Apply movement with sprint multiplier
		velocity.x = direction.x * SPEED * current_speed_multiplier
		velocity.z = direction.z * SPEED * current_speed_multiplier
	else:
		is_sprinting = false
		current_speed_multiplier = move_toward(current_speed_multiplier, 1.0, SPRINT_ACCELERATION * delta)
		velocity.x = move_toward(velocity.x, 0, SPEED * current_speed_multiplier)
		velocity.z = move_toward(velocity.z, 0, SPEED * current_speed_multiplier)

	move_and_slide()

func check_dodge(action: String, dir: Vector3):
	if Input.is_action_just_pressed(action) and can_dodge:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_since_last_tap = current_time - last_tap_time[action]
		
		if time_since_last_tap < DOUBLE_TAP_WINDOW:
			# Check if we have enough stamina to dodge
			if stats.has_enough_stamina(stats.dodge_stamina_cost):
				# Initiate dodge
				is_dodging = true
				dodge_timer = DODGE_DURATION
				dodge_direction = (transform.basis * dir).normalized()
				remaining_dodge_distance = DODGE_DISTANCE  # Reset dodge distance
				can_dodge = false
				dodge_cooldown_timer = DODGE_COOLDOWN
				# Use stamina for dodge
				stats.use_stamina(stats.dodge_stamina_cost)
			
		last_tap_time[action] = current_time
