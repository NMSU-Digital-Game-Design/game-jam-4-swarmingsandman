extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

@export var SPEED: float = 180.0         # a bit faster than normal enemies
@export var explode_range: float = 90.0  # how close before he starts to blow up
@export var explode_damage: int = 3
@export var fuse_time: float = 0.35      # time between starting and exploding
@export var max_health: int = 3          # how many bullet hits to kill

var exploding: bool = false
var fuse_timer: float = 0.0
var health: int

func _ready() -> void:
	health = max_health
	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if exploding:
		# already triggered, just wait for fuse to finish
		fuse_timer -= delta
		if fuse_timer <= 0.0:
			explode()
		return

	# normal chasing behavior
	var to_player: Vector2 = player.global_position - global_position
	var dir: Vector2 = to_player.normalized()

	# flip horizontally to face player (like your normal enemy)
	if dir.x != 0.0:
		anim.flip_h = dir.x < 0.0

	velocity = dir * SPEED
	move_and_slide()

	var distance: float = to_player.length()
	if distance <= explode_range:
		start_fuse()

func start_fuse() -> void:
	exploding = true
	fuse_timer = fuse_time
	velocity = Vector2.ZERO   # stop moving while fusing
	if anim:
		anim.play("attack")   # use an attack / flashing anim if you have one

func explode() -> void:
	print("Exploder exploding!")

	# damage the player
	if player != null and player.has_method("take_damage"):
		player.take_damage(explode_damage)

	# count as a kill – but do it safely
	var tree := get_tree()
	if tree != null:
		var main = tree.current_scene
		if main != null and main.has_method("register_kill"):
			main.register_kill()

	# remove this enemy after explosion
	queue_free()
	
# ---------- BULLET DAMAGE (now works) ----------
func take_damage(amount: int) -> void:
	health -= amount
	print("Exploder took damage, health:", health)
	if health <= 0:
		die()

func die() -> void:
	# Only die, no explosion damage here
	var main = get_tree().current_scene
	if main.has_method("register_kill"):
		main.register_kill()

	queue_free()
