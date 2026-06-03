class_name StunSkill
extends SkillBase

# ===== 雷电术 - 眩晕技能 =====
# 命中时：给敌人挂 StunController → 速度置 0 + 变黄 + 头顶粒子
# 多重命中：刷新剩余时间（取最大值）
# 倒计时结束：恢复原速 + 清除特效

@export var base_duration: float = 2.0  # 基础眩晕秒数，每级 +0.5s

# 只允许带"诅咒"标签的塔学习（Mage 塔）
func can_equip(tower_tags: Array) -> bool:
	return "诅咒" in tower_tags

# 子弹命中回调，由 SkillManager 统一调用
func on_hit(_tower: Node2D, _bullet: Node2D, target: Node2D,
		_damage: float, _is_crit: bool, skill_level: int) -> void:
	var data = get_level_data(skill_level)
	if data.is_empty() or not target.has_method("take_damage"):
		return
	var duration = base_duration + (skill_level - 1) * 0.5
	var ctrl = _get_or_create_stun(target)
	if ctrl:
		ctrl.apply(duration, target)

# 查找敌人身上已有的 StunController，没有则新建
func _get_or_create_stun(target: Node2D) -> Node:
	if not target.has_node("StunController"):
		var ctrl = Node.new()
		ctrl.name = "StunController"
		ctrl.set_script(preload("res://SkillSystem/skills/stun_controller.gd"))
		target.add_child(ctrl)
		return ctrl
	return target.get_node("StunController")

# 技能面板描述（BBCode 格式）
func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var duration = base_duration + (level - 1) * 0.5
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	desc += "\n类型: [color=yellow]雷电[/color]"
	desc += "\n眩晕: [color=white]%.1fs[/color]" % duration
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
