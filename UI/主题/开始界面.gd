extends Node2D

@onready var _start_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/StartBtn
@onready var _level_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/LevelBtn
@onready var _setting_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/SettingBtn
@onready var _exit_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/ExitBtn
@onready var _settings_panel = $CanvasLayer/Control/SettingsPanel
@onready var _level_scene = $CanvasLayer/Control/关卡选择

func _ready():
	AudioManager.play_music()
	_start_btn.pressed.connect(_on_start)
	_level_btn.pressed.connect(_on_level_select)
	_setting_btn.pressed.connect(_on_settings)
	_exit_btn.pressed.connect(_on_quit)
	# 关卡选择默认隐藏，点击"关卡选择"按钮再显示
	_level_scene.visible = false
	# 连接关卡选择面板的关闭按钮
	var close_btn = _level_scene.get_node("LevelSelectionUI/TextureRect/BottomButtons/CloseBtn")
	close_btn.pressed.connect(_on_level_close)
	# 连接关卡选择面板的退出按钮
	var exit_game_btn = _level_scene.get_node("LevelSelectionUI/ExitGameBtn")
	exit_game_btn.pressed.connect(_on_quit)

func _on_start():
	get_tree().change_scene_to_file("res://tower_defense.tscn")

func _on_level_select():
	# 显示关卡选择面板并刷新列表
	_level_scene.visible = true
	_level_scene.get_node("LevelSelectionUI").populate()

func _on_level_close():
	# 关闭关卡选择面板，回到开始界面
	_level_scene.visible = false

func _on_settings():
	_settings_panel.open()

func _on_quit():
	get_tree().quit()
