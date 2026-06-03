# 眩晕控制器 - 挂载到敌人身上，作为 Node 子节点
# 功能：置 speed=0 / 变黄 / 头顶粒子 / 倒计时恢复
# 生命周期：apply() → _process() 倒计时 → _restore() → queue_free()
# 多重眩晕：apply() 多次调用只刷新 _remaining_time，不会叠加新实例
# 减速+眩晕共存：启动时保存 speed（可能是减速后的值）→ 置 0 → 恢复后减速继续生效

extends Node

var _remaining_time: float = 0.0       # 剩余眩晕秒数
var _original_speed: float = -1.0       # 眩晕前的 speed（可能是减速后的值）
var _target: Node2D = null             # 被眩晕的敌人节点
var _sparkle: Node2D = null            # 头顶粒子实例

# 应用眩晕（可被同一技能多次调用，仅刷新持续时间）
func apply(duration: float, target_node: Node2D) -> void:
	# 取最大值：再次命中时延长眩晕而非重置
	_remaining_time = maxf(_remaining_time, duration)
	if _target:
		return
	_target = target_node
	if _target and "speed" in _target:
		_original_speed = _target.speed
		_target.speed = 0.0
		_target.modulate = Color(1, 0.9, 0.5)  # 黄色提示
	_spawn_sparkle()

# 每帧倒计时
func _process(delta: float) -> void:
	_remaining_time -= delta
	if _remaining_time <= 0:
		_restore()
		queue_free()

# 恢复敌人状态 + 清除粒子
func _restore() -> void:
	if _target and is_instance_valid(_target) and "speed" in _target:
		_target.speed = _original_speed
		_target.modulate = Color(1, 1, 1)  # 恢复白色
	if _sparkle and is_instance_valid(_sparkle):
		_sparkle.queue_free()
		_sparkle = null

# 在敌人头顶生成闪烁粒子（复用 mage_sparkle.tscn）
func _spawn_sparkle() -> void:
	if not _target:
		return
	var scene = preload("res://子弹/mage_sparkle.tscn")
	_sparkle = scene.instantiate()
	_sparkle.global_position = _target.global_position
	var root = _target.get_tree().current_scene if _target.get_tree() else null
	if root:
		root.add_child(_sparkle)

# 节点被移除时的安全清理（防止手动 queue_free 后敌人速度未恢复）
func _exit_tree() -> void:
	_restore()
