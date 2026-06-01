# Tower Type -- tower stat config resource
# 塔类型 -- 用 .tres 文件保存具体数值，改平衡不用碰代码
extends Resource
class_name TowerType

@export var display_name: String = "Tower"       # 显示名字
@export var damage: float = 5.0                  # 攻击力
@export var fire_rate: float = 1.0               # 射速（秒），每次攻击的冷却时间
@export var range_radius: float = 120.0          # 射程（像素），防御塔的攻击范围半径
@export var cost: int = 50                       # 购买价格
@export var scene: PackedScene                   # 塔场景文件（拖入 .tscn）
@export var bullet_scene: PackedScene            # 弹道场景（null=使用默认子弹）
