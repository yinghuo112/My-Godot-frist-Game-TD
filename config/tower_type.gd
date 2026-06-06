# Tower Type -- tower stat config resource
# 塔类型 -- 用 .tres 文件保存具体数值，改平衡不用碰代码
extends Resource
class_name TowerType

enum AttackType { PHYSICAL, MAGIC }

@export var display_name: String = "Tower"       # 显示名字
@export var damage: float = 5.0                  # 攻击力
@export var fire_rate: float = 1.0               # 射速（秒），每次攻击的冷却时间
@export var range_radius: float = 120.0          # 射程（像素），防御塔的攻击范围半径
@export var cost: int = 50                       # 购买价格
@export var scene: PackedScene                   # 塔场景文件（拖入 .tscn）
@export var bullet_scene: PackedScene            # 弹道场景（null=使用默认子弹）
@export var attack_type: AttackType = AttackType.PHYSICAL  # 攻击类型
@export var crit_chance: float = 0.1             # 暴击率
@export var crit_multiplier: float = 2.0         # 暴击倍率
@export var hit_chance: float = 0.95             # 命中率
@export var description: String = ""              # 技能描述（支持 BBCode）
@export var skill_book: Resource                   # 技能书
@export var skill_categories: Array = []           # 技能分类标签
@export var chain_jumps: int = 0                   # 链式跳跃次数（0=无连锁）
@export var chain_falloff: float = 1.0             # 跳跃伤害衰减系数
@export var chain_range: float = 0.0               # 跳跃搜索范围（像素）
@export var lightning_color: Color = Color(1, 1, 1) # 闪电主色，默认白
@export var lightning_line_count: int = 3          # 并行线条数

func can_equip_skill(skill) -> bool:
	if not skill_categories.is_empty() and skill.has_method("can_equip"):
		return skill.can_equip(skill_categories)
	return true
