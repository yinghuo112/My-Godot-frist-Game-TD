extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var _frame: int = 0
var _anim_timer: float = 0.0
const ANIM_FPS: float = 10.0
const FRAME_COUNT: int = 7

func _ready():
	if sprite:
		sprite.hframes = FRAME_COUNT
		sprite.frame = 0

func _process(delta):
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_frame += 1
		if _frame >= FRAME_COUNT:
			queue_free()
			return
		if sprite:
			sprite.frame = _frame
