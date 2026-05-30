extends Node2D
class_name TowerBase

@export var damage: float = 5.0
@export var fire_rate: float = 1.0
@export var range_radius: float = 120.0
@export var cost: int = 50
@export var show_range_circle: bool = false

# --- 升级系统 ---
var level: int = 1
var max_level: int = 3

var can_shoot: bool = true
var target: Node2D = null
var _tree_target: Node2D = null
var enemy_group: String = "enemy"
var bullet_scene = preload("res://scenes/bullet.tscn")

@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var level_label: Label = null

func _ready():
	range_shape.position = Vector2.ZERO
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = range_radius

	shoot_timer.wait_time = fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	range_area.collision_mask |= 2

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv." + str(level)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.position = Vector2(-10, -40)
	add_child(level_label)

func _process(delta):
	if target and is_instance_valid(target):
		if can_shoot:
			_shoot()
			can_shoot = false
			shoot_timer.start()

func _shoot():
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

	AudioManager.play_shoot()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.initialize(target, get_current_damage())

	var td_root = get_tree().root.get_node_or_null("TowerDefense")
	if td_root:
		td_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func _on_area_entered(area):
	if area.is_in_group(enemy_group):
		var parent = area.get_parent()
		if parent is GameTree:
			_tree_target = parent
			if not target:
				target = _tree_target
		elif not target or (target and is_instance_valid(target) and target is GameTree):
			target = parent

func _on_area_exited(area):
	var parent = area.get_parent()
	if parent == target:
		target = null
		if parent is GameTree:
			_tree_target = null
		_find_next_target()
	elif parent == _tree_target:
		_tree_target = null

func _find_next_target():
	var areas = range_area.get_overlapping_areas()
	var found_enemy = null
	var found_tree = null
	for a in areas:
		if not a.is_in_group(enemy_group) or not is_instance_valid(a.get_parent()):
			continue
		var p = a.get_parent()
		if p is GameTree:
			if not found_tree:
				found_tree = p
		elif not found_enemy:
			found_enemy = p
	if found_enemy:
		target = found_enemy
	elif found_tree:
		target = found_tree
	_tree_target = found_tree if found_tree else null

func _on_shoot_timer_timeout():
	if not target or not is_instance_valid(target):
		if sprite:
			sprite.stop()
	can_shoot = true

func _draw():
	if show_range_circle:
		draw_circle(Vector2.ZERO, range_radius, Color(1, 1, 1, 0.15))

# --- 升级接口（供 TowerActionRing 调用）---
func can_upgrade() -> bool:
	return level < max_level

func get_upgrade_cost() -> int:
	match level:
		1: return 80
		2: return 150
		_: return -1

func get_sell_value() -> int:
	var total = cost
	for lv in range(1, level):
		total += get_upgrade_cost_at(lv)
	return total / 2

func get_upgrade_cost_at(lv: int) -> int:
	match lv:
		1: return 80
		2: return 150
		_: return 0

func do_upgrade() -> bool:
	if not can_upgrade():
		return false
	var c = get_upgrade_cost()
	if not GameManager.spend_gold(c):
		return false
	level += 1
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = get_current_range()
	shoot_timer.wait_time = get_current_fire_rate()
	if level_label:
		level_label.text = "Lv." + str(level)
	return true

func get_current_damage() -> float:
	return damage * pow(1.5, level - 1)

func get_current_fire_rate() -> float:
	return fire_rate * pow(0.85, level - 1)

func get_current_range() -> float:
	return range_radius * pow(1.1, level - 1)
