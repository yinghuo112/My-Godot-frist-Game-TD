# Enemy Type -- monster stat config resource
# 怪物类型 -- 用 .tres 文件保存具体数值，改平衡不用碰代码
extends Resource
class_name EnemyType

@export var display_name: String = "Monster"     # 显示名字
@export var max_hp: float = 10.0                 # 最大生命
@export var speed: float = 150.0                 # 移动速度
@export var gold_reward: int = 10                # 击杀奖励金币
@export var lane_width: float = 40.0             # 变道宽度
@export var lane_change_speed: float = 120.0     # 超车速度
@export var scene: PackedScene                   # 怪物场景文件（拖入 .tscn）
@export var armor_physical: float = 0.0          # 物理减伤 (0~1)
@export var armor_magic: float = 0.0             # 魔法减伤 (0~1)
@export var dodge_chance: float = 0.0            # 闪避率 (0~1)
