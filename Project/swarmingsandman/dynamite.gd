extends Area2D

@export var fly_speed: float = 350.0      # how fast it flies
@export var travel_time: float = 0.4      # how long it flies before snapping to target
@export var fuse_time: float = 1.2        # how long it sits on the floor
@export var explode_radius: float = 90.0
@export var damage: int = 3

var target_pos: Vector2
var direction: Vector2 = Vector2.ZERO
var state: String = "idle"        # "idle" -> "flying" -> "armed"
var fly_timer: float = 0.0
var fuse_timer: float = 0.0

# Thrower calls this right after instancing
func launch(from_pos: Vector2, target: Vector2) -> void:
	global_position = from_pos
	target_pos = target
	direction = (target_pos - from_pos).normalized()
	rotation = direction.angle()

	state = "flying"
	fly_timer = travel_time
	print("Dynamite launched from:", from_pos, "to:", target)

func _physics_process(delta: float) -> void:
	if state == "flying":
		# just move in a straight line for a fixed time
		global_position += direction * fly_speed * delta
		fly_timer -= delta

		if fly_timer <= 0.0:
			# snap to the target when flight time is over
			global_position = target_pos
			land_on_floor()

	elif state == "armed":
		fuse_timer -= delta
		if fuse_timer <= 0.0:
			explode()

func land_on_floor() -> void:
	state = "armed"
	fuse_timer = fuse_time
	print("Dynamite landed at:", global_position)

func explode() -> void:
	print("Dynamite exploded at:", global_position)

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("take_damage"):
		var dist := player.global_position.distance_to(global_position)
		if dist <= explode_radius:
			player.take_damage(damage)

	queue_free()
