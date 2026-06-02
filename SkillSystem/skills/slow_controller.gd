extends Node

var _slow_ratio: float = 0.0
var _remaining_time: float = 0.0
var _original_speed: float = -1.0
var _target: Node2D = null

func apply(ratio: float, duration: float, target_node: Node2D) -> void:
	if _remaining_time > 0 and ratio <= _slow_ratio:
		_remaining_time = maxf(_remaining_time, duration)
		return
	_slow_ratio = ratio
	_remaining_time = duration
	_target = target_node
	if _target and "speed" in _target:
		if _original_speed < 0:
			_original_speed = _target.speed
		_target.speed = _original_speed * (1.0 - _slow_ratio)

func _process(delta: float) -> void:
	if _remaining_time <= 0:
		_restore_speed()
		queue_free()
		return
	_remaining_time -= delta

func _restore_speed() -> void:
	if _target and is_instance_valid(_target) and "speed" in _target:
		_target.speed = _original_speed

func _exit_tree() -> void:
	_restore_speed()
