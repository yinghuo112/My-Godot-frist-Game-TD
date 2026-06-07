# ========================================
# MobileAdapter.gd —— 手机适配模块核心单例
# ========================================
# 用法：注册为 AutoLoad，在任何地方调用 MobileAdapter.setup()
# 功能：平台检测、触摸相机控制、相机自适应缩放、UI 触摸优化、性能预设
# ========================================

extends Node

# ===== 信号 =====
signal screen_adapted(viewport_size: Vector2, is_landscape: bool)

# ===== 可配置参数（可在代码中修改）=====
var touch_friendly_min_size: Vector2 = Vector2(48, 48)  # 触控安全区最小尺寸
var camera_pan_speed: float = 1.0                        # 触摸拖拽相机速度系数
var zoom_min: float = 0.5                                # 最小缩放值
var zoom_max: float = 1.5                                # 最大缩放值
var design_width: float = 1280.0                         # 设计基准宽度
var design_height: float = 720.0                         # 设计基准高度
var enable_debug_button: bool = true                     # 手机端是否显示调试功能按钮
var auto_reduce_particles: bool = true                   # 手机端是否自动降低粒子数量

# ===== 内部状态 =====
var _is_mobile: bool = false
var _is_android: bool = false
var _is_ios: bool = false
var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _camera_start_pos: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.0
var _debug_btn: Button = null
var _btn_container: CanvasLayer = null

# ========================================
# 初始化
# ========================================

func _ready():
	_detect_platform()
	if _is_mobile:
		_apply_project_settings()
		_apply_performance_settings()

# 公开的完全初始化方法（游戏主场景就绪后调用一次）
func setup():
	_cache_camera()
	if _is_mobile:
		_adapt_camera()
		if enable_debug_button:
			_create_debug_button()
		print("MobileAdapter: 手机适配模块已就绪")
	else:
		print("MobileAdapter: PC 模式，跳过手机适配")

# ========================================
# 平台检测
# ========================================

func _detect_platform():
	var os_name = OS.get_name()
	_is_android = (os_name == "Android")
	_is_ios = (os_name == "iOS")
	_is_mobile = _is_android or _is_ios
	print("MobileAdapter: 当前平台 = ", os_name, "，是手机 = ", _is_mobile)

func is_mobile() -> bool:
	return _is_mobile

func is_android() -> bool:
	return _is_android

func is_ios() -> bool:
	return _is_ios

# ========================================
# 项目设置（运行时不可保存，但确保逻辑正确）
# ========================================

func _apply_project_settings():
	# Godot 4 默认会在手机端自动将触摸转鼠标事件，不需要额外设置
	# 这里只是日志确认
	print("MobileAdapter: 手机模式已激活")

# ========================================
# 相机控制（单指拖拽 + 双指捏合缩放）
# ========================================

func _cache_camera():
	_camera = get_viewport().get_camera_2d()
	if _camera and _camera.has_method("get_zoom_min"):
		zoom_min = _camera.get_zoom_min()
	if _camera and _camera.has_method("get_zoom_max"):
		zoom_max = _camera.get_zoom_max()

# 处理触摸输入：拖拽平移 + 捏合缩放
func _input(event: InputEvent):
	if not _is_mobile or not _camera:
		return

	# 单指拖拽平移相机
	if event is InputEventScreenDrag:
		if event.index == 0:
			_camera.position -= event.relative / _camera.zoom.x * camera_pan_speed
			_clamp_camera()

	# 双指捏合缩放
	if event is InputEventMagnifyGesture:
		var factor = event.factor
		var new_zoom = _camera.zoom.x * (1.0 / factor)
		_target_zoom = clamp(new_zoom, zoom_min, zoom_max)
		_camera.zoom = Vector2(_target_zoom, _target_zoom)
		_clamp_camera()

# 将相机限制在 play_area 内
func _clamp_camera():
	if not _camera:
		return
	if not GameManager or GameManager.play_area.size == Vector2.ZERO:
		return
	var viewport = get_viewport()
	if not viewport:
		return
	var window_size = viewport.get_visible_rect().size
	var half_w = window_size.x / (2.0 * _camera.zoom.x)
	var half_h = window_size.y / (2.0 * _camera.zoom.y)
	_camera.position.x = clamp(_camera.position.x,
		GameManager.play_area.position.x + half_w,
		GameManager.play_area.end.x - half_w)
	_camera.position.y = clamp(_camera.position.y,
		GameManager.play_area.position.y + half_h,
		GameManager.play_area.end.y - half_h)

# ========================================
# 相机自适应缩放（保持设计比例可见）
# ========================================

func _adapt_camera():
	if not _camera:
		_cache_camera()
		if not _camera:
			return
	var viewport = get_viewport()
	if not viewport:
		return
	var screen_size = viewport.get_visible_rect().size
	var aspect = screen_size.x / screen_size.y
	var base_aspect = design_width / design_height

	var new_zoom: float
	if aspect > base_aspect:
		# 屏幕比设计更宽：横向铺满，纵向会有余
		new_zoom = design_width / screen_size.x
	else:
		# 屏幕比设计更高：纵向铺满，横向会有余
		new_zoom = design_height / screen_size.y

	_target_zoom = clamp(new_zoom, zoom_min, zoom_max)
	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	_clamp_camera()

	screen_adapted.emit(screen_size, aspect > 1.0)
	print("MobileAdapter: 相机缩放调整为 ", _camera.zoom)

# 在屏幕旋转后重新适配
func adapt_camera():
	_adapt_camera()

# ========================================
# 调试按钮（手机端替代 F3/T/G 快捷键）
# ========================================

func _create_debug_button():
	if _debug_btn and is_instance_valid(_debug_btn):
		return
	_btn_container = CanvasLayer.new()
	_btn_container.name = "MobileDebugBtnLayer"
	_btn_container.layer = 128
	get_tree().root.add_child(_btn_container)

	var vbox = VBoxContainer.new()
	vbox.name = "DebugBtnBox"
	vbox.position = Vector2(4, 50)
	_btn_container.add_child(vbox)

	# 调试面板开关按钮
	var btn = Button.new()
	btn.text = "调试"
	btn.custom_minimum_size = Vector2(56, 36)
	btn.pressed.connect(_on_mobile_debug_toggle)
	vbox.add_child(btn)
	_debug_btn = btn

	# 生成测试怪物按钮
	var spawn_btn = Button.new()
	spawn_btn.text = "刷怪"
	spawn_btn.custom_minimum_size = Vector2(56, 36)
	spawn_btn.pressed.connect(_on_mobile_spawn_enemy)
	vbox.add_child(spawn_btn)

	# 复位相机按钮
	var reset_btn = Button.new()
	reset_btn.text = "复位"
	reset_btn.custom_minimum_size = Vector2(56, 36)
	reset_btn.pressed.connect(_on_mobile_reset_camera)
	vbox.add_child(reset_btn)

	print("MobileAdapter: 手机调试按钮已创建")

func _on_mobile_debug_toggle():
	var overlay = get_tree().root.get_node_or_null("DebugOverlay")
	if overlay and overlay.has_method("toggle"):
		overlay.toggle()

func _on_mobile_spawn_enemy():
	# 触发 main.gd 中的 _spawn_test_enemy()
	var main = get_tree().current_scene
	if main and main.has_method("_spawn_test_enemy"):
		main._spawn_test_enemy()

func _on_mobile_reset_camera():
	if not _camera:
		return
	_camera.position = Vector2(672, 341)
	_target_zoom = 1.0
	_camera.zoom = Vector2(1.0, 1.0)

# ========================================
# 性能优化（手机端自动降低特效）
# ========================================

func _apply_performance_settings():
	if not _is_mobile or not auto_reduce_particles:
		return
	# 粒子数量减半
	_particle_amount_scale(0.5)
	print("MobileAdapter: 手机性能优化已应用（粒子 50%）")

# 递归遍历场景树，调整 GPUParticles2D 的 amount
func _particle_amount_scale(scale_ratio: float):
	var root = get_tree().root
	_particle_scale_node(root, scale_ratio)

func _particle_scale_node(node: Node, ratio: float):
	if node is GPUParticles2D:
		var orig = node.get_meta("original_amount", node.amount)
		node.set_meta("original_amount", orig)
		node.amount = maxi(1, int(orig * ratio))
	for child in node.get_children():
		_particle_scale_node(child, ratio)

# ========================================
# UI 触摸友好工具函数
# ========================================

# 将按钮最小尺寸设为触控安全区
static func make_touch_friendly(button: BaseButton, min_size: Vector2 = Vector2(48, 48)):
	button.custom_minimum_size = min_size

# 获取当前触摸位置（手机优先触摸，PC 回退鼠标）
static func get_touch_pos() -> Vector2:
	var touch = Input.get_last_touch_screen_position(0)
	if touch != Vector2.ZERO:
		return touch
	return get_viewport().get_mouse_position()
