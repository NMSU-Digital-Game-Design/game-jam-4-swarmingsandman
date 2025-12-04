extends Node2D

@export var basic_enemy_scene: PackedScene      # normal enemy
@export var exploder_enemy_scene: PackedScene   # exploder enemy
@export var thrower_enemy_scene: PackedScene    # dynamite thrower

@export var start_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3
@export var time_to_max_difficulty: float = 120.0
@export var spawn_radius: float = 600.0

# --- Mini Swarm Settings ---
var swarm_interval := 20.0      # every 20 seconds a swarm happens
var swarm_duration := 4.0       # swarm lasts 4 seconds
var in_swarm: bool = false
var swarm_timer: float = 0.0
var next_swarm_time: float = 20.0   # first swarm at 20s

var time_since_last_spawn: float = 0.0
var elapsed_time: float = 0.0

var spawning_enabled: bool = false

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D


func set_active(value: bool) -> void:
	spawning_enabled = value

	# optional: reset timers when turning off
	if not value:
		elapsed_time = 0.0
		time_since_last_spawn = 0.0
		in_swarm = false
		swarm_timer = 0.0
		next_swarm_time = swarm_interval


func _ready() -> void:
	randomize()


func _process(delta: float) -> void:
	if not spawning_enabled:
		return            # do nothing while on the main menu

	if player == null or basic_enemy_scene == null:
		return

	elapsed_time += delta

		# ---- Swarm Trigger ----
	if elapsed_time >= next_swarm_time and not in_swarm:
		in_swarm = true
		swarm_timer = 0.0
		next_swarm_time += swarm_interval   # schedule next swarm
		print("🔥 MINI SWARM STARTED!")

		var main = get_tree().current_scene
		if main and main.has_method("show_swarm_message"):
			main.show_swarm_message("🔥 SWARM STARTED! 🔥", 2.0)

		# OPTIONAL: spawn an instant burst of enemies at swarm start
		for i in range(5):
			spawn_enemy()

	# If currently in a swarm, count down duration
	if in_swarm:
		swarm_timer += delta
		if swarm_timer >= swarm_duration:
			in_swarm = false
			print("SWARM ENDED!")

			var main = get_tree().current_scene
			if main and main.has_method("show_swarm_message"):
				main.show_swarm_message("SWARM ENDED!", 2.0)
	# Grace period at beginning of game
	if elapsed_time < 2.0:
		return

	time_since_last_spawn += delta

	var t: float = clamp(elapsed_time / time_to_max_difficulty, 0.0, 1.0)
	var current_interval: float = lerp(start_spawn_interval, min_spawn_interval, t)

	# Swarm = super fast spawns
	if in_swarm:
		current_interval *= 0.3   # 70% faster spawns (tweak this)

	if time_since_last_spawn >= current_interval:
		time_since_last_spawn = 0.0
		spawn_enemy()


func spawn_enemy() -> void:
	var scene: PackedScene = choose_enemy_scene()
	if scene == null:
		return

	var enemy: Node2D = scene.instantiate() as Node2D
	get_tree().current_scene.add_child(enemy)

	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spawn_radius
	enemy.global_position = player.global_position + offset


func choose_enemy_scene() -> PackedScene:
	var t: float = clamp(elapsed_time / time_to_max_difficulty, 0.0, 1.0)

	# safety: if others not set, fall back
	if exploder_enemy_scene == null and thrower_enemy_scene == null:
		return basic_enemy_scene

	if t < 0.33:
		# early game: only basic
		return basic_enemy_scene
	elif t < 0.66:
		# mid game: basic + exploders
		var roll := randf()
		if roll < 0.75:
			return basic_enemy_scene
		else:
			return exploder_enemy_scene if exploder_enemy_scene != null else basic_enemy_scene
	else:
		# late game: mix of all three
		var roll := randf()
		if roll < 0.5:
			return basic_enemy_scene
		elif roll < 0.8:
			return exploder_enemy_scene if exploder_enemy_scene != null else basic_enemy_scene
		else:
			return thrower_enemy_scene if thrower_enemy_scene != null else basic_enemy_scene
