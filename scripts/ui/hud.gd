extends Control

@onready var hp_bar = $VBoxContainer/HPBar
@onready var stamina_bar = $VBoxContainer/StaminaBar
@onready var mana_bar = $VBoxContainer/ManaBar

@onready var spell_grid = $SpellGrid
@onready var spellbook = get_node("/root/MainScene/Spellbook") # Update path to match the actual scene structure

@onready var spell_slots = $SpellGrid.get_children()
var prepared_spells = []

# Function to update the HUD
func update_bars(hp: float, max_hp: float, stamina: float, max_stamina: float, mana: float, max_mana: float):
	hp_bar.value = (hp / max_hp) * 100
	stamina_bar.value = (stamina / max_stamina) * 100
	mana_bar.value = (mana / max_mana) * 100

func update_spell_grid():
	for i in range(spell_slots.size()):
		if i < prepared_spells.size():
			spell_slots[i].texture = prepared_spells[i].icon  # Assign icon
		else:
			spell_slots[i].texture = null  # Empty slot

func set_prepared_spells(spells):
	prepared_spells = spells
	update_spell_grid()

func _ready():
	# Hide HUD elements by default
	spell_grid.hide()
	if spellbook:
		spellbook.hide()
	
	# Show only the spell grid initially
	spell_grid.show()
	
	print("HUD initialized")

func _process(_delta):
	# Add any HUD update logic here
	pass
