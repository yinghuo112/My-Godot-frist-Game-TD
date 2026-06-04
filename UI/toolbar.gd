extends Control

# ===== 工具栏（全宽顶部条） =====
# 左侧：资源显示（金币/生命/波数）
# 中间：Start Wave 按钮
# 右侧：速度控制（1×/2×/4×/暂停）+ 设置 + 调试
#
# 速度按钮互斥：点击一个速度后，该按钮置 disabled（灰显）
# 暂停按钮置 disabled 时表示已暂停
# Engine.time_scale 在 1.0 / 2.0 / 4.0 / 0.0 之间切换

signal speed_changed(speed_scale: float)
signal settings_pressed()
signal debug_pressed()

var _current_speed: float = 1.0
var _paused: bool = false

@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
@onready var start_btn: Button = %StartWaveBtn
@onready var speed_1x: Button = %Speed1xBtn
@onready var speed_2x: Button = %Speed2xBtn
@onready var speed_4x: Button = %Speed4xBtn
@onready var pause_btn: Button = %PauseBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var debug_btn: Button = %DebugBtn

func _ready():
	Engine.time_scale = 1.0
	speed_1x.pressed.connect(_on_speed.bind(1.0))
	speed_2x.pressed.connect(_on_speed.bind(2.0))
	speed_4x.pressed.connect(_on_speed.bind(4.0))
	pause_btn.pressed.connect(_on_pause)
	settings_btn.pressed.connect(_on_settings)
	debug_btn.pressed.connect(_on_debug)
	_update_speed_buttons()

func _on_speed(scale: float):
	_current_speed = scale
	_paused = false
	Engine.time_scale = scale
	_update_speed_buttons()
	speed_changed.emit(scale)

func _on_pause():
	_paused = not _paused
	if _paused:
		Engine.time_scale = 0.0
		speed_changed.emit(0.0)
	else:
		Engine.time_scale = _current_speed
		speed_changed.emit(_current_speed)
	_update_speed_buttons()

func _on_settings():
	settings_pressed.emit()

func _on_debug():
	debug_pressed.emit()

# 更新速度按钮高亮状态
# 规则：当前速度的按钮 disabled（灰显），其他 enabled
func _update_speed_buttons():
	var btns = [speed_1x, speed_2x, speed_4x]
	var speeds = [1.0, 2.0, 4.0]
	for i in range(btns.size()):
		btns[i].disabled = (_current_speed == speeds[i] and not _paused)
	# 暂停按钮独立高亮
	pause_btn.disabled = _paused
