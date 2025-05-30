extends CharacterBody3D

# Movement settings
@export var speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var rotation_x = 0.0

# Dodge settings
const DODGE_DISTANCE = 10.0  # Distance covered in dodge
const DODGE_DURATION = 0.3   # How long the dodge lasts
const DOUBLE_TAP_TIME = 0.3  # Maximum time between taps to register a dodge

var last_tap_time = {"ui_up": 0.0, "ui_down": 0.0, "ui_left": 0.0, "ui_right": 0.0}
var dodge_timer = 0.0
var is_dodging = false
var dodge_direction = Vector3.ZERO

@onready var camera = $Camera3D
@onready var player_stats = $PlayerStats

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Mouse Look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * (mouse_sensitivity * 100)
		rotation_x = clamp(rotation_x, -90, 90)
		camera.rotation_degrees.x = rotation_x

	# Unlock mouse with Escape
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Handle Sprinting
	var current_speed = speed
	if Input.is_action_pressed("sprint") and player_stats.stamina > 0:
		current_speed = sprint_speed
		player_stats.set_sprinting(true)
		player_stats.use_stamina(10 * delta)
	else:
		player_stats.set_sprinting(false)

	# Apply Normal Movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not is_dodging:
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * delta * 5)
			velocity.z = move_toward(velocity.z, 0, speed * delta * 5)

	# Check for double-tap dodge
	if check_double_tap("ui_up"):
		start_dodge(-transform.basis.z)
	elif check_double_tap("ui_down"):
		start_dodge(transform.basis.z)
	elif check_double_tap("ui_left"):
		start_dodge(-transform.basis.x)
	elif check_double_tap("ui_right"):
		start_dodge(transform.basis.x)

	# Handle dodge timer and friction
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
			player_stats.set_dodging(false)
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

func check_double_tap(action_name):
	if Input.is_action_just_pressed(action_name) and not is_dodging:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_tap_time[action_name] <= DOUBLE_TAP_TIME:
			last_tap_time[action_name] = 0.0
			return true
		last_tap_time[action_name] = current_time
	return false

func start_dodge(direction: Vector3):
	if direction != Vector3.ZERO and player_stats.stamina >= 20:
		is_dodging = true
		dodge_timer = DODGE_DURATION
		velocity.x = direction.x * DODGE_DISTANCE / DODGE_DURATION
		velocity.z = direction.z * DODGE_DISTANCE / DODGE_DURATION
		player_stats.set_dodging(true)  # When dodging starts
		player_stats.use_stamina(20)
		print("Dodging! Stamina left:", player_stats.stamina)

func _process(_delta):
	if Input.is_action_just_pressed("take_damage(debug)"):
		player_stats.take_damage(10)
		print("Damage taken! Current HP:", player_stats.hp)
