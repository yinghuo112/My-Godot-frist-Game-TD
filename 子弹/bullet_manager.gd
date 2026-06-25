# ===== 子弹对象池管理器（Autoload）=====
# 全局单例，管理多种子弹池（箭矢、魔法弹、法师弹）
# 塔通过 get_node("/root/BulletManager").get_bullet(scene) 获取子弹
extends Node

var _pools: Dictionary = {}          # { scene_resource_path: BulletPool }

# 启动时预注册子弹池，各预分配若干,防止卡顿
func _ready():
	register_pool(preload("res://子弹/bullet.tscn"), 20)
	register_pool(preload("res://子弹/magic_bolt.tscn"), 15)
	register_pool(preload("res://子弹/mage_bolt.tscn"), 15)
	register_pool(preload("res://子弹/lightning_bolt.tscn"), 10)
	register_pool(preload("res://子弹/fireball_bullet.tscn"), 15)
	register_pool(preload("res://子弹/雪球/雪球.tscn"), 15)	
# 注册一种子弹池，如场景不存在则自动创建
func register_pool(scene: PackedScene, size: int) -> void:
	var pool = BulletPool.new(scene, size)
	add_child(pool)
	_pools[scene.resource_path] = pool

# 从对应池中取出一颗子弹，未注册则自动注册
func get_bullet(scene: PackedScene) -> Node2D:
	var path = scene.resource_path
	if not _pools.has(path):
		register_pool(scene, 10)
	return _pools[path].get_bullet()
