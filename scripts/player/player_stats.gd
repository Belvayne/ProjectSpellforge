extends Node

signal stats_updated(hp, max_hp, stamina, max_stamina, mana, max_mana)

var hp = 100
var max_hp = 100
var stamina = 100
var max_stamina = 100
var mana = 100
var max_mana = 100

var casting_speed = 100
var spellpower = 10

var stamina_regen_rate = 10
var is_sprinting = false
var is_dodging = false

func take_damage(amount):
	hp = max(0, hp - amount)
	print("Player took", amount, "damage. HP:", hp)
	emit_signal("stats_updated", hp, max_hp, stamina, max_stamina, mana, max_mana)


func use_stamina(amount: int):
	if stamina > 0:
		stamina = max(0, stamina - amount)
		emit_signal("stats_updated", hp, max_hp, stamina, max_stamina, mana, max_mana)

func use_mana(amount: int):
	mana = max(0, mana - amount)
	emit_signal("stats_updated", hp, max_hp, stamina, max_stamina, mana, max_mana)

func regenerate_stamina(delta):
	if stamina < max_stamina and not is_sprinting and not is_dodging:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
		emit_signal("stats_updated", hp, max_hp, stamina, max_stamina, mana, max_mana)

func _process(delta):
	# Regenerate stamina when not sprinting or dodging
	regenerate_stamina(delta)

func set_sprinting(state: bool):
	is_sprinting = state
	if not state:
		regenerate_stamina(0)  # Immediately start regenerating stamina when sprint stops

func set_dodging(state: bool):
	is_dodging = state
	if not state:
		regenerate_stamina(0)  # Immediately start regenerating stamina when dodge stops
