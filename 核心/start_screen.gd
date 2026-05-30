extends Control

@onready var settings_panel: Control = $SettingsPanel
@onready var level_panel: Control = $LevelSelectPanel

# 初始化主菜单：播放音乐，连接按钮信号
func _ready():
	AudioManager.play_music()
	$CenterContainer/VBox/StartBtn.pressed.connect(_on_start)
	$CenterContainer/VBox/LevelBtn.pressed.connect(_on_level_select)
	$CenterContainer/VBox/SettingsBtn.pressed.connect(_on_settings)
	$CenterContainer/VBox/QuitBtn.pressed.connect(_on_quit)
	level_panel.hide()

# 点击开始按钮：进入游戏场景
func _on_start():
	get_tree().change_scene_to_file("res://tower_defense.tscn")

# 点击关卡选择按钮：显示关卡面板
func _on_level_select():
	level_panel.show()
	level_panel.populate()

# 点击设置按钮：打开设置面板
func _on_settings():
	settings_panel.open()

# 点击退出按钮：退出游戏
func _on_quit():
	get_tree().quit()
