class_name PanelBase
extends PanelContainer


# 面板宽度（像素），用于计算滑出偏移量，子类可覆盖
const PANEL_WIDTH: float = 300.0

# 信号：面板关闭时发出，外部可监听做清理
signal closed()

# 当前操作的目标塔
var _target_tower: Node2D = null

# 滑入/滑出动画控制器
var _tween: Tween = null

# 面板是否处于打开状态
var _is_open: bool = false

# 关闭按钮引用（子类在 _ready 中赋值）
var _close_btn: Button = null


# ===== 生命周期 =====

func _ready() -> void:
	# 初始隐藏，面板默认不显示
	hide_instantly()


# ===== 公共 API =====

# 打开面板并滑入显示（子类调用此方法作为入口）
func show_panel() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	visible = true
	_is_open = true
	# 滑入动画：从右侧偏移到原位（匀速）
	_tween = create_tween().set_ease(Tween.EASE_LINEAR).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_property(self, "offset_left", 0.0, 0.3)

# 关闭面板并滑出隐藏（带动画）
func close() -> void:
	if not _is_open:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	# 滑出动画：从原位偏移到右侧屏幕外
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "offset_left", _get_panel_width() + 20.0, 0.25)
	_tween.tween_callback(_on_close_finished)

# 无动画立即隐藏（用于初始化或强制重置）
func hide_instantly() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	offset_left = _get_panel_width() + 20.0
	visible = false
	_is_open = false


# ===== 虚函数（子类按需覆盖） =====

# 返回面板宽度，用于计算滑出偏移量
func _get_panel_width() -> float:
	return PANEL_WIDTH

# 填充面板内容（子类必须实现）
func _populate(_target: Node2D) -> void:
	pass

# 关闭完成后的额外逻辑（子类按需覆盖）
func _on_close_extra() -> void:
	pass


# ===== 内部方法 =====

# 连接关闭按钮（子类在 _ready 中调用）
func _connect_close_btn(btn: Button) -> void:
	_close_btn = btn
	if _close_btn:
		_close_btn.pressed.connect(close)

# 滑出动画完成后的回调
func _on_close_finished() -> void:
	visible = false
	_is_open = false
	closed.emit()
	_on_close_extra()

# Escape 键关闭处理
func _input(event: InputEvent) -> void:
	if _is_open and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
