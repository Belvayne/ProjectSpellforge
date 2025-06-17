extends Node

var current_health = 1000000
var max_health = 1000000

func take_damage(amount):
	current_health -= amount
	if current_health < 0:
		current_health = 0
	get_parent().update_health_display()
	print("Dummy took ", amount, " damage. Health: ", current_health) 