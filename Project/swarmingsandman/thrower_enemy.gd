extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

@export var SPEED: float = 90.0
@export var preferred_distance: float = 420.0   # desired distance from player
@export var distance_tolerance: float = 80.0    # acceptable range around desired
@export var throw_interval: float = 2.0         # seconds between throws
@export var max_health: int = 4
@export var dynamite_scene: PackedScene         # set this to Dynamite.tscn in Inspector

var health: int
var throw_timer: float = 0.0

func _ready() -> void:
	health = max_health
	throw_timer = throw_interval
	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	throw_timer -= delta

	var to_player: Vector2 = player.global_position - global_position
	var dir: Vector2 = to_player.normalized()
	var distance: float = to_player.length()

	# face toward player (flip sprite left/right)
	if dir.x != 0.0:
		anim.flip_h = dir.x < 0.0

	# keep a medium distance
	if distance > preferred_distance + distance_tolerance:
		velocity = dir * SPEED              # move closer
	elif distance < preferred_distance - distance_tolerance:
		velocity = -dir * SPEED             # back up
	else:
		velocity = Vector2.ZERO             # stay put

	move_and_slide()

	# walk animation when moving
	if velocity.length() > 5.0 and anim.animation != "walk":
		anim.play("walk")

	# throw periodically
	if throw_timer <= 0.0:
		throw_timer = throw_interval
		throw_dynamite()

func throw_dynamite() -> void:
	if dynamite_scene == null or player == null:
		return

	if anim:
		anim.play("attack")

	var dynamite = dynamite_scene.instantiate()
	get_tree().current_scene.add_child(dynamite)

	var start_pos: Vector2 = global_position
	var target_pos: Vector2 = player.global_position

	if dynamite.has_method("launch"):
		dynamite.launch(start_pos, target_pos)
	else:
		# fallback, but you really should have launch()
		dynamite.global_position = start_pos

	if anim:
		anim.play("walk")

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	var main = get_tree().current_scene
	if main.has_method("register_kill"):
		main.register_kill()
	queue_free()
