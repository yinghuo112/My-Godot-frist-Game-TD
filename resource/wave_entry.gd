extends Resource
class_name WaveEntry

@export var enemy_scene: PackedScene  # 怪物场景（旧方式，逐步废弃）
@export var enemy_type: EnemyType     # 怪物类型数据（新数据驱动方式）
@export var count: int = 8            # 本波怪物数量
@export var spawn_interval: float = 0.5  # 生成间隔（秒）
