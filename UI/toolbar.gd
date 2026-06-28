extends Control

# =============================================================================
# 工具栏（全宽顶部条）
# 提供：金币/血量/波次显示、开始波次、路线切换、速度控制、菜单
# 所有用户操作均通过信号向上层（父节点）传递，自身不包含游戏逻辑
# =============================================================================

## 当用户点击“开始波次”按钮时发射
signal wave_start_requested

## 当用户点击菜单（MenuBtn）中的任意项时发射，参数为菜单项 ID
signal menu_action(action_id: int)

## 当用户切换路线时发射，参数为新路线编号（1 或 2）
signal route_changed(route: int)

# ----- 私有状态 --------------------------------------------------------------

## 当前选中的时间缩放倍率（0.5/1.0/2.0/4.0）
var _current_speed: float = 1.0

## 是否处于暂停状态（时间缩放为 0）
var _paused: bool = false

## 当前选中的路线编号（1 或 2）
var _current_route: int = 1

# ----- 生命周期 --------------------------------------------------------------

func _ready() -> void:
	Engine.time_scale = 1.0
	_setup_buttons()
	_setup_menu()
	_update_speed_buttons()
	_update_route_buttons()

# ----- 内部初始化 ------------------------------------------------------------

## 连接所有按钮的信号到内部处理方法
## 注意：菜单按钮（MenuBtn）的弹出菜单通过 id_pressed 连接
func _setup_buttons() -> void:
	%StartWaveBtn.pressed.connect(_on_start_wave)
	%Route1Btn.pressed.connect(_on_route.bind(1))
	%Route2Btn.pressed.connect(_on_route.bind(2))
	%Speed05xBtn.pressed.connect(_on_speed.bind(0.5))
	%Speed1xBtn.pressed.connect(_on_speed.bind(1.0))
	%Speed2xBtn.pressed.connect(_on_speed.bind(2.0))
	%Speed4xBtn.pressed.connect(_on_speed.bind(4.0))
	%PauseBtn.pressed.connect(_on_pause)
	%MenuBtn.get_popup().id_pressed.connect(_on_menu_selected)

# ----- 菜单初始化（代码添加菜单项，.tscn 的 item_* 属性会被处理器丢弃） ------

func _setup_menu() -> void:
	var popup = %MenuBtn.get_popup()
	popup.add_item("⚙ 设置", 0)
	popup.add_item("📖 说明", 1)
	popup.add_item("🔧 调试", 2)
	popup.add_item("返回主页", 3)
	popup.add_separator()     # 下划线
	popup.add_item("ℹ 关于", 5)

# ----- 对外接口（供父节点或外部调用） --------------------------------------

## 更新金币显示
## @param value: 金币数量
func set_gold(value: int) -> void:
	%GoldLabel.text = "%d" % value

## 更新生命值显示
## @param value: 生命数量
func set_lives(value: int) -> void:
	%LivesLabel.text = "%d" % value

## 更新波次信息（当前波次/总波次）及进度条
## @param current: 当前波次数
## @param total: 总波次数
func set_wave(current: int, total: int) -> void:
	%WaveLabel.text = "WAVE %d/%d" % [current, total]
	%WaveProgressBar.max_value = total
	%WaveProgressBar.value = current

## 设置“开始波次”按钮的禁用状态
## @param disabled: true 为禁用
func set_start_btn_disabled(disabled: bool) -> void:
	%StartWaveBtn.disabled = disabled

## 设置“开始波次”按钮的显示文字
## @param text: 按钮文本
func set_start_btn_text(text: String) -> void:
	%StartWaveBtn.text = text

## 设置“开始波次”按钮的可见性
## @param visible_state: true 显示，false 隐藏
func set_start_btn_visible(visible_state: bool) -> void:
	%StartWaveBtn.visible = visible_state

## 启用/禁用双路线模式，并更新路线按钮的文字
## @param enabled: 是否启用双路线
## @param layout: 预设布局标识（"cross" 时显示"上环/下环"，否则为"路线1/路线2"）
func set_dual_mode(enabled: bool, layout: String = "") -> void:
	%Route1Btn.visible = enabled
	%Route2Btn.visible = enabled
	if enabled:
		if layout == "cross":
			%Route1Btn.text = "上环"
			%Route2Btn.text = "下环"
		else:
			%Route1Btn.text = "路线1"
			%Route2Btn.text = "路线2"
		# 如果当前路线无效（为 0），重置为路线 1
		if _current_route == 0:
			_on_route(1)

# ----- 路线切换 --------------------------------------------------------------

## 处理路线选择（由按钮 pressed 触发）
## @param route: 1 或 2
func _on_route(route: int) -> void:
	_current_route = route
	_update_route_buttons()
	route_changed.emit(route)   # 通知父节点

## 更新路线按钮的禁用状态（当前选中的按钮被禁用）
func _update_route_buttons() -> void:
	%Route1Btn.disabled = _current_route == 1
	%Route2Btn.disabled = _current_route == 2

# ----- 菜单处理 --------------------------------------------------------------

## 处理菜单项选中（由 PopupMenu 的 id_pressed 触发）
## @param id: 菜单项 ID
func _on_menu_selected(id: int) -> void:
	AudioManager.play("ui_click")
	menu_action.emit(id)        # 将菜单 ID 转发给父节点

# ----- 波次控制 --------------------------------------------------------------

## 处理“开始波次”按钮点击
func _on_start_wave() -> void:
	AudioManager.play("ui_click")
	wave_start_requested.emit() # 通知父节点开始波次

# ----- 速度与暂停 ------------------------------------------------------------

## 处理速度切换（0.5x / 1x / 2x / 4x）
## @param speed: 目标时间缩放值
func _on_speed(speed: float) -> void:
	AudioManager.play("ui_click")
	_current_speed = speed
	_paused = false
	Engine.time_scale = speed
	_update_speed_buttons()

## 处理暂停/继续切换
func _on_pause() -> void:
	AudioManager.play("ui_click")
	_paused = not _paused
	Engine.time_scale = 0.0 if _paused else _current_speed
	_update_speed_buttons()

## 更新速度按钮和暂停按钮的禁用状态
## 速度按钮：当前选中速度（且未暂停）时禁用
## 暂停按钮：暂停时禁用（可改为显示“继续”样式，但此处仅禁用）
func _update_speed_buttons() -> void:
	var btns = [%Speed05xBtn, %Speed1xBtn, %Speed2xBtn, %Speed4xBtn]
	var speeds = [0.5, 1.0, 2.0, 4.0]
	for i in range(btns.size()):
		btns[i].disabled = (_current_speed == speeds[i] and not _paused)
	%PauseBtn.text = "|>" if _paused else "||"
	%PauseBtn.disabled = false   # 注：暂停时禁用暂停按钮（可能不符合直觉，建议改为切换文本）
