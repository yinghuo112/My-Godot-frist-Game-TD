class_name SkillBase
extends Resource

@export var name: String = ""
@export var tags: Array = []
@export var description: String = ""
@export var max_level: int = 5
@export var prerequisites: Array = []
@export var required_tower_level: int = 1
@export var gold_cost: int = 0
@export var level_table: Array = []

func can_equip(_tower_tags: Array) -> bool:
	return true

func on_pre_shot(tower: Node2D, bullet: Node2D, target: Node2D, skill_level: int) -> void:
	pass

func on_hit(tower: Node2D, bullet: Node2D, target: Node2D,
		damage: float, is_crit: bool, skill_level: int) -> void:
	pass

func on_tower_tick(tower: Node2D, delta: float, skill_level: int) -> void:
	pass

func get_level_data(level: int) -> Dictionary:
	var idx = level - 1
	if idx >= 0 and idx < level_table.size():
		return level_table[idx]
	return {}

func get_cost_points(level: int) -> int:
	return get_level_data(level).get("cost_points", 0)

func get_cost_proficiency(level: int) -> int:
	return get_level_data(level).get("cost_prof", 0)

func get_damage(level: int) -> float:
	return get_level_data(level).get("damage", 0.0)

func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	if data.has("damage") and data.damage > 0:
		desc += "\n伤害: [color=yellow]%.1f[/color]" % data.damage
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
