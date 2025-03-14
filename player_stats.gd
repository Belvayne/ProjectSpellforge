extends Node

signal stamina_changed(current_stamina, max_stamina)
signal health_changed(current_health, max_health)
signal mana_changed(current_mana, max_mana)

# Base stats
var max_health: float = 100.0
var max_mana: float = 100.0
var max_stamina: float = 100.0

# Current stats
var current_health: float = max_health
var current_mana: float = max_mana
var current_stamina: float = max_stamina

# Regeneration rates (per second)
var stamina_regen_rate: float = 20.0
var mana_regen_rate: float = 10.0

# Costs
var dodge_stamina_cost: float = 25.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	regenerate_stamina(delta)
	regenerate_mana(delta)

func regenerate_stamina(delta):
	if current_stamina < max_stamina:
		current_stamina = min(current_stamina + (stamina_regen_rate * delta), max_stamina)
		emit_signal("stamina_changed", current_stamina, max_stamina)

func regenerate_mana(delta):
	if current_mana < max_mana:
		current_mana = min(current_mana + (mana_regen_rate * delta), max_mana)
		emit_signal("mana_changed", current_mana, max_mana)

func has_enough_stamina(cost: float) -> bool:
	return current_stamina >= cost

func use_stamina(amount: float) -> bool:
	if has_enough_stamina(amount):
		current_stamina -= amount
		emit_signal("stamina_changed", current_stamina, max_stamina)
		return true
	return false

func modify_health(amount: float):
	current_health = clamp(current_health + amount, 0, max_health)
	emit_signal("health_changed", current_health, max_health)

func use_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana, max_mana)
		return true
	return false
