extends Node

@export var base_xp_to_next: int = 100      # first level: 100 XP
@export var xp_increase_per_level: int = 50 # +50 needed each level

var current_xp: int = 0
var level: int = 1
var xp_to_next: int

@onready var xp_label: Label = get_node_or_null("../UI/XpLabel") as Label

func _ready() -> void:
	xp_to_next = base_xp_to_next
	_update_xp_label()


func add_xp(amount: int, player: Node) -> void:
	current_xp += amount

	# In case you gain lots of XP at once, loop
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1

		# Tell player they leveled up
		if player and player.has_method("on_level_up"):
			player.on_level_up(level)

		# 🔺 increase requirement: 100, 150, 200, 250, ...
		xp_to_next += xp_increase_per_level

	_update_xp_label()


func _update_xp_label() -> void:
	if xp_label:
		xp_label.text = "XP: %d / %d  (Lv %d)" % [current_xp, xp_to_next, level]
