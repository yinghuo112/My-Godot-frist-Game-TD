extends Control

# ===== 工具栏（全宽顶部条） =====
# 左侧：图标 + 金币/血量/波次数字
# 中间：Start Wave 按钮
# 右侧：速度控制 + 设置 + 调试
#
# 外部通过本脚本的信号和方法交互，不直接访问内部节点

signal wave_start_requested
signal settings_requested
signal debug_requested

var _current_speed: float = 1.0
var _paused: bool = false

func _ready():
	Engine.time_scale = 1.0
	_setup_buttons()
	_update_speed_buttons()

func _setup_buttons():
	%StartWaveBtn.pressed.connect(wave_start_requested.emit)
	%Speed1xBtn.pressed.connect(_on_speed.bind(1.0))
	%Speed2xBtn.pressed.connect(_on_speed.bind(2.0))
	%Speed4xBtn.pressed.connect(_on_speed.bind(4.0))
	%PauseBtn.pressed.connect(_on_pause)
	%SettingsBtn.pressed.connect(settings_requested.emit)
	%DebugBtn.pressed.connect(debug_requested.emit)

# ===== 外部接口 =====

func set_gold(value: int):
	%GoldLabel.text = "%d" % value

func set_lives(value: int):
	%LivesLabel.text = "%d" % value

func set_wave(current: int, total: int):
	%WaveLabel.text = "WAVE %d/%d" % [current, total]
	%WaveProgressBar.max_value = total
	%WaveProgressBar.value = current

func set_start_btn_disabled(disabled: bool):
	%StartWaveBtn.disabled = disabled

func set_start_btn_text(text: String):
	%StartWaveBtn.text = text

func set_start_btn_visible(visible_state: bool):
	%StartWaveBtn.visible = visible_state

# ===== 速度控制 =====

func _on_speed(speed: float):
	_current_speed = speed
	_paused = false
	Engine.time_scale = speed
	_update_speed_buttons()

func _on_pause():
	_paused = not _paused
	Engine.time_scale = 0.0 if _paused else _current_speed
	_update_speed_buttons()

func _update_speed_buttons():
	var btns = [%Speed1xBtn, %Speed2xBtn, %Speed4xBtn]
	var speeds = [1.0, 2.0, 4.0]
	for i in range(btns.size()):
		btns[i].disabled = (_current_speed == speeds[i] and not _paused)
	%PauseBtn.disabled = _paused
