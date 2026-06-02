extends Node2D
class_name TowerRangeIndicator

var radius: float = 120.0
var _angle: float = 0.0

const DASH_LENGTH: float = 24.0
const GAP_LENGTH: float = 20.0
const LINEAR_SPEED: float = 44.0

func _process(delta):
	var angular_speed = LINEAR_SPEED / radius
	_angle += delta * angular_speed
	queue_redraw()

func _draw():
	var step_angle = (DASH_LENGTH + GAP_LENGTH) / radius
	var dash_angle = DASH_LENGTH / radius
	var count = maxi(1, int(TAU * radius / (DASH_LENGTH + GAP_LENGTH)))
	for i in range(count):
		var start = _angle + i * step_angle
		draw_arc(Vector2.ZERO, radius, start, start + dash_angle,
			4, Color(1, 1, 1, 0.5), 2.0, true)

func set_range(r: float):
	radius = r
	queue_redraw()
