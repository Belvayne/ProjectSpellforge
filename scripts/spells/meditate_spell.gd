extends Node3D

@export var health_regen_rate: float = 5.0  # Health per second
@export var mana_regen_rate: float = 10.0  # Mana per second
@export var tick_rate: float = 0.5  # Time between regeneration ticks

var player_stats = null
var is_active = false
var tick_timer = 0.0

func _ready():
	# Get the player stats node
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_stats = player.get_node("PlayerStats")
		if not player_stats:
			print("PlayerStats not found!")
			queue_free()
			return
	else:
		print("Player not found!")
		queue_free()
		return

func _process(delta):
	if is_active and player_stats:
		tick_timer += delta
		if tick_timer >= tick_rate:
			tick_timer = 0.0
			regenerate_stats()

func start_meditation():
	is_active = true
	print("Meditation started")

func stop_meditation():
	is_active = false
	print("Meditation stopped")

func regenerate_stats():
	if player_stats:
		# Regenerate health
		var health_gain = health_regen_rate * tick_rate
		player_stats.hp = min(player_stats.max_hp, player_stats.hp + health_gain)
		
		# Regenerate mana
		var mana_gain = mana_regen_rate * tick_rate
		player_stats.mana = min(player_stats.max_mana, player_stats.mana + mana_gain)
		
		print("Regenerated ", health_gain, " health and ", mana_gain, " mana")
		
		# Emit signal to update HUD
		player_stats.emit_signal("stats_updated", 
			player_stats.hp, player_stats.max_hp,
			player_stats.stamina, player_stats.max_stamina,
			player_stats.mana, player_stats.max_mana) 