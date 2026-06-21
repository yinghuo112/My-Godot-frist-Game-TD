extends Node2D

const DURATION = 0.3
const SPARK_COUNT = 6

var _timer: float = 0.0
var _offsets: Array = []

func _ready():
	for i in range(SPARK_COUNT):
		_offsets.append(Vector2(randf_range(-8, 8), randf_range(-8, 8)))

func _process(delta):
	_timer += delta
	if _timer >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var t = _timer / DURATION
	var alpha = 1.0 - t
	var r = 8.0 + t * 35.0
	draw_circle(Vector2.ZERO, r, Color(1, 0.5, 0, alpha * 0.5))
	draw_circle(Vector2.ZERO, r * 0.7, Color(1, 0.8, 0.2, alpha * 0.35))
	draw_circle(Vector2.ZERO, r * 0.4, Color(1, 1, 0.6, alpha * 0.2))
	for offset in _offsets:
		var spark_r = 2.0 + t * 12.0
		draw_circle(offset * (1.0 + t * 2.0), spark_r, Color(1, 0.65, 0.05, alpha * 0.4))
