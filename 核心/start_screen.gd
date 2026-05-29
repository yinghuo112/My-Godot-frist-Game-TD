extends Control

@onready var settings_panel: Control = $SettingsPanel
@onready var level_panel: Control = $LevelSelectPanel

func _ready():
	AudioManager.play_music()
	$CenterContainer/VBox/StartBtn.pressed.connect(_on_start)
	$CenterContainer/VBox/LevelBtn.pressed.connect(_on_level_select)
	$CenterContainer/VBox/SettingsBtn.pressed.connect(_on_settings)
	$CenterContainer/VBox/QuitBtn.pressed.connect(_on_quit)
	level_panel.hide()

func _on_start():
	get_tree().change_scene_to_file("res://tower_defense.tscn")

func _on_level_select():
	level_panel.show()
	level_panel.populate()

func _on_settings():
	settings_panel.open()

func _on_quit():
	get_tree().quit()
