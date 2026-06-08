class_name SkillBase
extends Resource

# ===== 技能基础属性（在 .tres 子资源中配置）=====
@export var name: String = ""             # 技能显示名
@export var tags: Array = []              # 技能标签（如 ["元素", "火焰"]，用于匹配塔的分类）
@export var description: String = ""      # 技能描述文本
@export var max_level: int = 5            # 最大等级
@export var prerequisites: Array = []     # 前置技能索引（指向 skill_book.skills[]）
@export var required_tower_level: int = 1 # 塔需要达到多少级才能解锁
@export var gold_cost: int = 0            # 解锁所需金币
@export var level_table: Array = []       # 每级数据表（dict 数组，各技能自定义字段）



# ===== 技能的特殊效果(是否有弹射，辐射，喷射，散射，光环，召唤)====

# ===== 技能挂载点（子类重写这些方法实现效果）=====

# 判断该技能是否能被指定标签的塔装备
func can_equip(_tower_tags: Array) -> bool:
	return true

# 子弹发射前回调，在 tower_base._shoot() 中调用
# 可修改子弹属性或替换子弹场景
func on_pre_shot(_tower: Node2D, _bullet: Node2D, _target: Node2D, _skill_level: int) -> void:
	pass

# 子弹命中敌人回调，在 bullet._apply_damage() 中调用
# 用于附加效果（溅射、中毒、减速、眩晕等）
func on_hit(_tower: Node2D, _bullet: Node2D, _target: Node2D,
		_damage: float, _is_crit: bool, _skill_level: int) -> void:
	pass

# 塔每 0.5s 的 tick 回调，在 tower_base._process() 中调用
# 用于持续效果管理（冷却倒计时、状态刷新等）
func on_tower_tick(_tower: Node2D, _delta: float, _skill_level: int) -> void:
	pass

# ===== 等级数据读取工具 =====

# 获取指定等级的 level_table dict（1-indexed）
func get_level_data(level: int) -> Dictionary:
	var idx = level - 1
	if idx >= 0 and idx < level_table.size():
		return level_table[idx]
	return {}

# 获取指定等级升级所需技能点数
func get_cost_points(level: int) -> int:
	return get_level_data(level).get("cost_points", 0)

# 获取指定等级升级所需熟练度
func get_cost_proficiency(level: int) -> int:
	return get_level_data(level).get("cost_prof", 0)

# 获取指定等级附加伤害
func get_damage(level: int) -> float:
	return get_level_data(level).get("damage", 0.0)

# 生成技能面板的 BBCode 描述文本
func get_bbcode_description(level: int = 1) -> String:
	var data = get_level_data(level)
	var desc = "[b]%s (Lv.%d)[/b]" % [name, level]
	if data.has("damage") and data.damage > 0:
		desc += "\n伤害: [color=yellow]%.1f[/color]" % data.damage
	if data.has("special") and data.special != "":
		desc += "\n[color=lightblue]%s[/color]" % data.special
	return desc
