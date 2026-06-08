class_name FireballSkill
extends SkillBase

const _MAGIC_EXPLOSION = preload("res://子弹/magic_explosion.tscn")

# ===== 溅射参数（可在 .tres 子资源中覆盖）=====
@export var splash_radius: float = 60.0      # 溅射范围半径（像素）
@export var splash_damage_ratio: float = 0.5 # 溅射伤害 = 暴击后最终伤害 × 此比例

# 只允许带"元素"标签的塔学习
func can_equip(tower_tags: Array) -> bool:
	return "元素" in tower_tags

# 命中时：对溅射范围内除主目标外的敌人造成范围伤害
func on_hit(tower: Node2D, bullet: Node2D, target: Node2D,
		damage: float, _is_crit: bool, skill_level: int) -> void:
	var data = get_level_data(skill_level)
	if data.is_empty():
		return
	var extra_dmg = data.get("damage", 0.0)
	var splash_dmg = extra_dmg + damage * splash_damage_ratio
	var radius = splash_radius * (1.0 + (skill_level - 1) * 0.15)
	_spawn_explosion(bullet.global_position, radius, tower)
	_damage_nearby(target, bullet.global_position, radius, splash_dmg)

# 生成爆炸特效
func _spawn_explosion(pos: Vector2, radius: float, tower: Node2D) -> void:
	var explosion = _MAGIC_EXPLOSION.instantiate()
	explosion.global_position = pos
	explosion.scale = Vector2(radius / 30.0, radius / 30.0)
	var root = tower.get_tree().current_scene
	if root:
		root.add_child(explosion)

# 对溅射范围内除主目标外的敌人造成伤害（PhysicsShapeQuery）
func _damage_nearby(target: Node2D, pos: Vector2, radius: float, damage: float) -> void:
	var space = target.get_world_2d().direct_space_state
	if not space:
		return
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	query.set_shape(circle)
	query.transform = Transform2D(0, pos)
	query.collision_mask = 2
	var results = space.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if not collider or not is_instance_valid(collider):
			continue
		var enemy = collider.owner if collider.owner else collider.get_parent()
		if enemy == target:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, false)

# 技能面板描述（BBCode 格式）
func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var radius = splash_radius * (1.0 + (level - 1) * 0.15)
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	desc += "\n类型: [color=orange]元素·火焰[/color]"
	desc += "\n溅射范围: [color=white]%.0f[/color]" % radius
	if data.has("damage") and data.damage > 0:
		desc += "\n附加伤害: [color=yellow]%.1f[/color]" % data.damage
	desc += "\n溅射比例: %d%%" % int(splash_damage_ratio * 100)
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
