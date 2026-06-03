class_name PoisonSkill
extends SkillBase

@export var tick_interval: float = 1.0
@export var base_duration: float = 4.0

func can_equip(tower_tags: Array) -> bool:
	return "元素" in tower_tags

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

func _get_or_create_poison(target: Node2D) -> Node:
	if not target.has_node("PoisonController"):
		var ctrl = Node.new()
		ctrl.name = "PoisonController"
		ctrl.set_script(preload("res://SkillSystem/skills/poison_controller.gd"))
		target.add_child(ctrl)
		return ctrl
	return target.get_node("PoisonController")

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
