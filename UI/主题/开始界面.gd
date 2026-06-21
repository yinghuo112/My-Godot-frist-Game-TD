extends Node2D

@onready var _start_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/StartBtn
@onready var _level_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/LevelBtn
@onready var _setting_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/SettingBtn
@onready var _exit_btn = $CanvasLayer/Control/CenterContainer/VBoxContainer/ButtonContainer/ExitBtn
@onready var _level_panel = $CanvasLayer/Control/LevelSelectPanel
@onready var _settings_panel = $CanvasLayer/Control/SettingsPanel

func _ready():
	AudioManager.play_music()
	_start_btn.pressed.connect(_on_start)
	_level_btn.pressed.connect(_on_level_select)
	_setting_btn.pressed.connect(_on_settings)
	_exit_btn.pressed.connect(_on_quit)

func _on_start():
	get_tree().change_scene_to_file("res://tower_defense.tscn")

func _on_level_select():
	_level_panel.show_panel()
	_level_panel.populate()

func _on_settings():
	_settings_panel.open()

func _on_quit():
	get_tree().quit()
