class_name SlowSkill
extends SkillBase

const _SLOW_CONTROLLER = preload("res://SkillSystem/skills/slow_controller.gd")

# ===== 减速参数（可在 .tres 子资源中覆盖）=====
@export var slow_ratio: float = 0.4       # 减速比例（0.4 = 速度降至 60%）
@export var base_duration: float = 3.0    # 基础持续时间（秒），每级 +0.5s

# 只允许带"诅咒"标签的塔学习
func can_equip(tower_tags: Array) -> bool:
	return "诅咒" in tower_tags

# 命中时：给敌人挂 SlowController，降低移动速度
func on_hit(_tower: Node2D, _bullet: Node2D, target: Node2D,
		_damage: float, _is_crit: bool, skill_level: int) -> void:
	var data = get_level_data(skill_level)
	if data.is_empty() or not target.has_method("take_damage"):
		return
	var ratio = slow_ratio + (skill_level - 1) * 0.05
	var duration = base_duration + (skill_level - 1) * 0.5
	var slow = _get_or_create_slow(target)
	if slow:
		slow.apply(ratio, duration, target)

# 查找敌人身上已有的 SlowController，没有则新建
func _get_or_create_slow(target: Node2D) -> Node:
	if not target.has_node("SlowController"):
		var ctrl = Node.new()
		ctrl.name = "SlowController"
		ctrl.set_script(_SLOW_CONTROLLER)
		target.add_child(ctrl)
		return ctrl
	return target.get_node("SlowController")

# 技能面板描述（BBCode 格式）
func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var ratio = slow_ratio + (level - 1) * 0.05
	var duration = base_duration + (level - 1) * 0.5
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	desc += "\n类型: [color=purple]诅咒[/color]"
	desc += "\n减速: [color=white]%d%%[/color]" % int(ratio * 100)
	desc += "\n持续时间: %.1fs" % duration
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
