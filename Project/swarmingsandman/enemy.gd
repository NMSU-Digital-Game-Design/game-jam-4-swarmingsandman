extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

@export var SPEED: float = 120.0
@export var max_health: int = 3
@export var damage: int = 1
@export var attack_range: float = 105.0      # must be right on you
@export var attack_cooldown: float = 1.0     # one hit per second

var health: int
var attack_timer: float = 0.0

func _ready() -> void:
	health = max_health
	if anim:
		anim.play("walk")   # default idle/walk loop

func _physics_process(delta: float) -> void:
	if player == null:
		return

	attack_timer -= delta

	var to_player: Vector2 = player.global_position - global_position
	var dir: Vector2 = to_player.normalized()
	var distance: float = to_player.length()

	if dir.x != 0:
		anim.flip_h = dir.x < 0
	
	# Move toward player
	velocity = dir * SPEED
	move_and_slide()

	# Attack only when very close, and cooldown ready
	if distance <= attack_range and attack_timer <= 0.0:
		# play attack animation while hitting
		if anim.animation != "attack":
			anim.play("attack")
		attack_player()
	else:
		# go back to walk when not attacking
		if anim.animation != "walk":
			anim.play("walk")

func attack_player() -> void:
	attack_timer = attack_cooldown
	if player != null and player.has_method("take_damage"):
		print("Enemy attacking player")
		player.take_damage(damage)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	var main = get_tree().current_scene
	if main.has_method("register_kill"):
		main.register_kill()
	queue_free()
