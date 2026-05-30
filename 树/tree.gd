extends Node2D
class_name GameTree

signal died(gold_reward)

enum State { SAPLING, MATURE }

@export var grow_time: float = 15.0
@export var max_hp: float = 30.0
@export var gold_reward: int = 15

var state: int = State.SAPLING
var current_hp: float
var is_marked: bool = false

@onready var visual: ColorRect = $Visual
@onready var area: Area2D = $Area2D
@onready var grow_timer: Timer = $GrowTimer

func _ready():
	current_hp = max_hp
	_update_visual()
	grow_timer.wait_time = grow_time
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	grow_timer.start()
	area.monitoring = false
	area.monitorable = false

func _update_visual():
	match state:
		State.SAPLING:
			visual.color = Color(0.3, 0.8, 0.3)
			visual.size = Vector2(24, 24)
			visual.position = Vector2(-12, -12)
		State.MATURE:
			visual.color = Color(0.5, 0.3, 0.15)
			visual.size = Vector2(40, 40)
			visual.position = Vector2(-20, -20)

func _on_grow_timer_timeout():
	state = State.MATURE
	_update_visual()
	grow_timer.stop()

func mark():
	if state != State.MATURE or is_marked:
		return
	is_marked = true
	area.monitoring = true
	area.monitorable = true
	area.add_to_group("enemy")
	visual.modulate = Color(1, 0.7, 0.4)

func unmark():
	if not is_marked:
		return
	is_marked = false
	area.monitoring = false
	area.monitorable = false
	area.remove_from_group("enemy")
	visual.modulate = Color.WHITE

func take_damage(amount: float):
	current_hp = maxf(current_hp - amount, 0)
	var hp_ratio = current_hp / max_hp
	visual.color = Color(
		0.5 + 0.5 * hp_ratio,
		0.3 * hp_ratio,
		0.15 * hp_ratio
	)
	if current_hp <= 0:
		die()

func die():
	died.emit(gold_reward)
	queue_free()
