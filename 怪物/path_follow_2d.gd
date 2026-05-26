extends PathFollow2D

@export var speed: float = 120.0

var last_position: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	sprite.play("new_animation")
	last_position = global_position

func _process(delta):
	progress += speed * delta
	var horizontal_movement = global_position.x - last_position.x
	if horizontal_movement < 0:
		sprite.flip_h = true
	elif horizontal_movement > 0:
		sprite.flip_h = false
	last_position = global_position
	if progress_ratio >= 1.0:
		queue_free()
