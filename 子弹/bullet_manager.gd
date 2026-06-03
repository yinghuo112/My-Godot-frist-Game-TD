

extends Node

var _pools: Dictionary = {}

func _ready():
	register_pool(preload("res://子弹/bullet.tscn"), 20)
	register_pool(preload("res://子弹/magic_bolt.tscn"), 15)
	register_pool(preload("res://子弹/mage_bolt.tscn"), 15)

func register_pool(scene: PackedScene, size: int) -> void:
	var pool = BulletPool.new(scene, size)
	add_child(pool)
	_pools[scene.resource_path] = pool

func get_bullet(scene: PackedScene) -> Node2D:
	var path = scene.resource_path
	if not _pools.has(path):
		register_pool(scene, 10)
	return _pools[path].get_bullet()
