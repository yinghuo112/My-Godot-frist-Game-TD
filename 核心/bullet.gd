extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10

var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready():
	area_entered.connect(_on_area_entered)

func initialize(p_target: Node2D, p_damage: float) -> void:
	target = p_target
	damage = p_damage
	if is_instance_valid(target):
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		look_at(target.global_position)
		if global_position.distance_to(target.global_position) < 12.0:
			_hit()
			return
	else:
		if velocity == Vector2.ZERO:
			velocity = Vector2.RIGHT.rotated(rotation) * speed
		if global_position.distance_to(Vector2.ZERO) > 3000:
			queue_free()
			return
	global_position += velocity * delta

func _hit() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		queue_free()
