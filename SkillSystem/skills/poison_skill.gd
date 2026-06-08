class_name PoisonSkill
extends SkillBase

const _POISON_CONTROLLER = preload("res://SkillSystem/skills/poison_controller.gd")

# ===== 中毒参数（可在 .tres 子资源中覆盖）=====
@export var tick_interval: float = 1.0   # 每跳间隔（秒）
@export var base_duration: float = 4.0   # 基础持续时间（秒），每级 +1s

# 只允许带"元素"标签的塔学习
func can_equip(tower_tags: Array) -> bool:
	return "元素" in tower_tags

# 命中时：给敌人挂 PoisonController，开始持续掉血
func on_hit(_tower: Node2D, _bullet: Node2D, target: Node2D,
		_damage: float, _is_crit: bool, skill_level: int) -> void:
	var data = get_level_data(skill_level)
	if data.is_empty() or not target.has_method("take_damage"):
		return
	var tick_dmg = data.get("damage", 0.0)
	var duration = base_duration + (skill_level - 1) * 1.0
	var poison = _get_or_create_poison(target)
	if poison:
		poison.apply(tick_dmg, duration, tick_interval, target)

# 查找敌人身上已有的 PoisonController，没有则新建
func _get_or_create_poison(target: Node2D) -> Node:
	if not target.has_node("PoisonController"):
		var ctrl = Node.new()
		ctrl.name = "PoisonController"
		ctrl.set_script(_POISON_CONTROLLER)
		target.add_child(ctrl)
		return ctrl
	return target.get_node("PoisonController")

# 技能面板描述（BBCode 格式）
func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var duration = base_duration + (level - 1) * 1.0
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	desc += "\n类型: [color=green]元素·毒[/color]"
	if data.has("damage") and data.damage > 0:
		desc += "\n每跳伤害: [color=yellow]%.1f[/color]" % data.damage
	desc += "\n持续时间: %.1fs" % duration
	desc += "\n间隔: %.1fs" % tick_interval
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
