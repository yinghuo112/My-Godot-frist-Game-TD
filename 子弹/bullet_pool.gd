class_name BulletPool
extends Node

var scene_file: PackedScene
var _available: Array = []
var _all: Array = []
var _max_size: int = 200

func _init(scene: PackedScene, prealloc: int):
	scene_file = scene
	for i in range(prealloc):
		_create_new()

func _create_new() -> Node2D:
	if _all.size() >= _max_size:
		return null
	var bullet = scene_file.instantiate()
	bullet._pool_managed = true
	bullet.visible = false
	bullet.set_process(false)
	bullet.set_physics_process(false)
	if bullet.has_method("set_monitoring"):
		bullet.set_monitoring(false)
	if bullet.has_signal("used_up"):
		bullet.used_up.connect(return_bullet)
	add_child(bullet)
	_all.append(bullet)
	_available.append(bullet)
	return bullet

func get_bullet() -> Node2D:
	if _available.is_empty():
		var b = _create_new()
		if not b:
			return null
	var bullet = _available.pop_back()
	if bullet.get_parent():
		bullet.get_parent().remove_child(bullet)
	bullet.visible = true
	bullet.set_process(true)
	bullet.set_physics_process(true)
	if bullet.has_method("set_monitoring"):
		bullet.set_monitoring(true)
	return bullet

func return_bullet(bullet: Node2D) -> void:
	if bullet.get_parent():
		bullet.get_parent().remove_child(bullet)
	add_child(bullet)
	bullet.visible = false
	bullet.set_process(false)
	bullet.set_physics_process(false)
	if bullet.has_method("set_monitoring"):
		bullet.set_monitoring(false)
	_available.append(bullet)
