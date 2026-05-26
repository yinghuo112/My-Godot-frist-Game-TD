class_name Enemy
extends PathFollow2D

signal died(enemy)
signal reached_end

@export var speed: float = 150.0
@export var max_hp: float = 10.0
@export var gold_reward: int = 10

var current_hp: float
var _last_pos: Vector2 = Vector2.ZERO  # 初始化避免第一帧计算异常

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar

func _ready():
	current_hp = max_hp
	if sprite:
		sprite.play("walk")
	_update_health_bar()


func _process(delta: float) -> void:
	progress += speed * delta
	var dx := global_position.x - _last_pos.x
	if dx < 0:
		sprite.flip_h = true
	elif dx > 0:
		sprite.flip_h = false
	_last_pos = global_position
	if progress_ratio >= 1.0:
		reach_end()


func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0)
	_update_health_bar()
	if current_hp <= 0:
		die()

func reach_end():
	emit_signal("reached_end")
	queue_free()

func die():
	emit_signal("died", self)
	queue_free()

func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
