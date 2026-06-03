extends PathFollow2D

@export var _speed: float = 120.0

var last_position: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# 初始化：播放动画，记录初始位置
func _ready():
	sprite.play("new_animation")
	last_position = global_position

# 每帧沿路径前进，根据移动方向翻转精灵，到达终点时销毁
func _process(delta):
	progress += _speed * delta
	var horizontal_movement = global_position.x - last_position.x
	if horizontal_movement < 0:
		sprite.flip_h = true
	elif horizontal_movement > 0:
		sprite.flip_h = false
	last_position = global_position
	if progress_ratio >= 1.0:
		queue_free()
