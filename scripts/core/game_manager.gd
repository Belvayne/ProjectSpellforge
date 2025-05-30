extends Node

var player
var player_stats
var hud
var pause_menu

func _ready():
	# Wait until the next frame to ensure all nodes exist
	await get_tree().process_frame  

	# Get node references AFTER the scene has fully loaded
	player = get_node_or_null("/root/MainScene/Player")
	player_stats = get_node_or_null("/root/MainScene/Player/PlayerStats")
	hud = get_node_or_null("/root/MainScene/HUD")
	pause_menu = get_node_or_null("/root/MainScene/PauseMenu")

	# Ensure all nodes were found before proceeding
	if not player or not player_stats or not hud or not pause_menu:
		print("Error: Some nodes were not found in GameManager!")
		return

	# Connect signals safely
	player_stats.stats_updated.connect(hud.update_bars)

	# Ensure PauseMenu starts hidden
	pause_menu.visible = false

	print("GameManager initialized successfully!")
