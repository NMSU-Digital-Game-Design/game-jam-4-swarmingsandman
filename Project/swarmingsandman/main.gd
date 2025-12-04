extends Node2D

var game_started: bool = false
var kill_count: int = 0
var can_play: bool = false


@onready var start_menu: Control = $UI/StartMenu
@onready var kill_label: Label = $UI/KillLabel
@onready var health_label: Label = $UI/healthLabel
@onready var upgrade_label: Label = $UI/UpgradeLabel
@onready var weapon_label: Label = $UI/WeaponLabel
@onready var weapon_stats_label: Label = $UI/WeaponStatsLabel
@onready var swarm_label: Label = $UI/SwarmLabel

func _ready() -> void:
	game_started = false
	_update_kill_label()
	_update_health_label(0, 0)
	
	if upgrade_label:
		upgrade_label.visible = false
		upgrade_label.text = ""

	# show start menu
	if start_menu:
		start_menu.visible = true
	
	if weapon_stats_label:
		weapon_stats_label.text = "Pistol K:0 L:1 | Shotgun K:0 L:1 | Rifle K:0 L:1"

	# stop player + spawner until Start is pressed
	var player = get_node_or_null("Player")
	if player and player.has_method("set_can_play"):
		player.set_can_play(false)

	var spawner = get_node_or_null("EnemySpawner")
	if spawner and spawner.has_method("set_active"):
		spawner.set_active(false)

func set_can_play(value: bool) -> void:
	can_play = value

# called by enemies when they die
func register_kill() -> void:
	kill_count += 1
	_update_kill_label()

	# Get player once
	var player = get_node_or_null("Player")

	# --- Give XP for the kill ---
	var xp_manager = get_node_or_null("XPManager")
	if xp_manager and xp_manager.has_method("add_xp") and player:
		xp_manager.add_xp(5, player)   # <-- now passing 2 args: amount + player

	# --- Weapon unlock logic based on kills ---
	if player and player.has_method("on_kill_count_changed"):
		player.on_kill_count_changed(kill_count)
		
	if player and player.has_method("on_weapon_kill"):
		player.on_weapon_kill()
		
	_update_weapon_label(player)

func update_health(current: int, max_health: int) -> void:
	_update_health_label(current, max_health)

# --------- UPGRADE POPUP ---------
func show_upgrade_message(text: String, duration: float = 3.0) -> void:
	if upgrade_label == null:
		return

	upgrade_label.text = text
	upgrade_label.visible = true

	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func ():
		if upgrade_label:
			upgrade_label.visible = false
			upgrade_label.text = ""
	)

# --------- internal helpers ---------
func _update_kill_label() -> void:
	if kill_label != null:
		kill_label.text = "Kills: %d" % kill_count

func _update_health_label(current: int, max_health: int) -> void:
	if health_label != null:
		health_label.text = "HP: %d / %d" % [current, max_health]

func _update_weapon_label(player: Node) -> void:
	if weapon_label == null:
		return

	if player == null or not player.has_method("get_weapon_kill_stats"):
		return

	var stats: Dictionary = player.get_weapon_kill_stats()
	var pistol := int(stats.get("pistol", 0))
	var shotgun := int(stats.get("shotgun", 0))
	var rifle := int(stats.get("rifle", 0))

	weapon_label.text = "Pistol: %d   Shotgun: %d   Rifle: %d" % [pistol, shotgun, rifle]

func update_weapon_stats(
	pistol_kills: int, pistol_level: int,
	shotgun_kills: int, shotgun_level: int,
	rifle_kills: int, rifle_level: int
) -> void:
	if weapon_stats_label:
		weapon_stats_label.text = "P:%dK L%d | S:%dK L%d | R:%dK L%d" % [
			pistol_kills, pistol_level,
			shotgun_kills, shotgun_level,
			rifle_kills, rifle_level
		]

# --------- START BUTTON CALLBACK ---------
# Connect StartButton.pressed() signal to this in the editor

func _on_start_button_pressed() -> void:
	game_started = true

	if start_menu:
		start_menu.visible = false

	var player = get_node_or_null("Player")
	if player and player.has_method("set_can_play"):
		player.set_can_play(true)

	var spawner = get_node_or_null("EnemySpawner")
	if spawner and spawner.has_method("set_active"):
		spawner.set_active(true)
		
func show_swarm_message(text: String, duration: float = 2.0) -> void:
	if swarm_label == null:
		return

	swarm_label.text = text
	swarm_label.visible = true

	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if swarm_label:
			swarm_label.visible = false
	)
