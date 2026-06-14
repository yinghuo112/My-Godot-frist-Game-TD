extends Resource
## 波次类型：提供每小波的怪物数量和时间间隔
class_name 每波设置

## 怪物场景（旧方式，逐步废弃）
## @export var enemy_scene: PackedScene
## 拖入 EnemyType 的 .tres 资源（含血量/速度/奖励金等完整属性）
@export var enemy_type: EnemyType
@export var count: int = 8
@export var spawn_interval: float = 0.5
## 路线编号（1=路线1/上环, 2=路线2/下环）
@export var route: int = 1
