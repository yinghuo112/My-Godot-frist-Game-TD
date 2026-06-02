extends Node

var _tick_damage: float = 0.0
var _remaining_time: float = 0.0
var _tick_interval: float = 1.0
var _tick_timer: float = 0.0
var _target: Node2D = null

func apply(tick_dmg: float, duration: float, interval: float, target_node: Node2D) -> void:
	_tick_damage = maxf(_tick_damage, tick_dmg)
	_remaining_time = maxf(_remaining_time, duration)
	_tick_interval = interval
	_target = target_node
	_tick_timer = 0.0

func _process(delta: float) -> void:
	if _remaining_time <= 0:
		queue_free()
		return
	_remaining_time -= delta
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer -= _tick_interval
		if _target and is_instance_valid(_target) and _target.has_method("take_damage"):
			_target.take_damage(_tick_damage, false)
