extends "res://子弹/bullet.gd"

@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _path_node: Path2D = null
var _baked_offset: float = 0.0
var _move_dir: int = -1             # -1 = 朝起点（怪巢方向）
var _hit_enemies: Array = []        # 记录攻击到的敌人，防止重复伤害
var knockback_force: float = 50.0   # 击退力度
var _initialized: bool = false      # 是否已完成初始化


# 初始化：从目标或 MapManager 获取 Path2D
func initialize(p_target, p_damage,
	p_crit_chance = 0.0, p_crit_mult = 1.0,
	p_hit_chance = 1.0, p_attack_type = 0,
	p_source_tower = null, p_cached_skills = []):
	super(p_target, p_damage, p_crit_chance, p_crit_mult,
		p_hit_chance, p_attack_type, p_source_tower, p_cached_skills)
	if is_instance_valid(p_target):
		var parent_path = p_target.get_parent()
		if parent_path is Path2D:
			_path_node = parent_path
	if not _path_node:
		var mm = _get_map_manager()
		if mm and mm.enemy_path:
			_path_node = mm.enemy_path
	if _path_node:
		_baked_offset = _path_node.curve.get_closest_offset(global_position)
	if _anim_sprite:
		_anim_sprite.play("滚动")
	_initialized = true

# 沿 Path2D 曲线滚动（不追踪目标）
func _physics_process(delta):
	if not _initialized:
		return
	var mm = _get_map_manager()
	if not mm or not mm.play_area.has_point(global_position):
		call_deferred("_release")
		return
	if not _path_node:
		call_deferred("_release")
		return
	_baked_offset += _move_dir * _speed * delta
	var length = _path_node.curve.get_baked_length()
	if _baked_offset <= 0 or _baked_offset >= length:
		call_deferred("_release")
		return
	global_position = _path_node.curve.sample_baked(_baked_offset)

# 碰撞敌人：伤害 + 击退（接口预留）

func _on_area_entered(area):
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy in _hit_enemies:
			return
		_hit_enemies.append(enemy)
		_apply_damage(enemy)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(knockback_force)
		
		
## 子弹回池时，清空攻击到的敌人列表
func reset():
	super()
	_hit_enemies.clear()
