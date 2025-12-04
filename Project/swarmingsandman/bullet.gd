extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1
@export var max_pierce: int = 1   # how many enemies it can pass through

var direction: Vector2 = Vector2.ZERO
var pierce_count: int = 0

func _physics_process(delta: float) -> void:
	# if direction is zero, do nothing
	if direction == Vector2.ZERO:
		return
	
	position += direction * speed * delta

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		pierce_count += 1
		if pierce_count >= max_pierce:
			queue_free()
