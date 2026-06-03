# ===== 子弹对象池 =====
# 管理同类子弹的复用池，避免频繁 instantiate / queue_free
# 子弹命中后 → _release() → used_up 信号 → return_bullet() → 回到池中
# 塔射击时 → get_bullet() → reset() → 重新激活发射
class_name BulletPool
extends Node

var scene_file: PackedScene          # 池子管理的子弹场景文件
var _available: Array = []           # 可用的空闲子弹列表
var _all: Array = []                 # 池子创建的所有子弹（含已借出的）
var _max_size: int = 200             # 池子最大容量，防止无限增长

# 构造函数：指定子弹场景 + 预分配数量
func _init(scene: PackedScene, prealloc: int):
	scene_file = scene
	for i in range(prealloc):
		_create_new()

# 创建一颗新子弹 → 设置 _pool_managed → 连接 used_up 信号 → 禁用后入池
func _create_new() -> Node2D:
	if _all.size() >= _max_size:
		return null
	var bullet = scene_file.instantiate()
	bullet._pool_managed = true
	if bullet.has_signal("used_up"):
		bullet.used_up.connect(return_bullet)
	add_child(bullet)
	bullet.visible = false
	bullet.set_process(false)
	bullet.set_physics_process(false)
	bullet.set_deferred("monitoring", false)
	if bullet.has_node("CollisionShape2D"):
		bullet.get_node("CollisionShape2D").set_deferred("disabled", true)
	_all.append(bullet)
	_available.append(bullet)
	return bullet

# 从池中取出一颗子弹 → 调用 reset() 恢复可见/碰撞/物理 → 交给塔发射
func get_bullet() -> Node2D:
	if _available.is_empty():
		var b = _create_new()
		if not b:
			return null
	var bullet = _available.pop_back()
	if bullet.get_parent():
		bullet.get_parent().remove_child(bullet)
	bullet.reset()
	return bullet

# 子弹使用完毕回到池中 → re-parent 到池节点 → 加入空闲列表
# 注意：清理逻辑（visible=false / 禁用碰撞）已在 bullet._release() 中处理
func return_bullet(bullet: Node2D) -> void:
	if bullet.get_parent():
		bullet.get_parent().remove_child(bullet)
	add_child(bullet)
	_available.append(bullet)
