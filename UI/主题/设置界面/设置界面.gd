extends PanelContainer

@onready var fs_btn: CheckButton = $主面板/HBoxContainer/CheckButton
@onready var music_slider: HSlider = $主面板/音量盒/HSlider
@onready var sfx_slider: HSlider = $主面板/音效盒/HSlider

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	fs_btn.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	music_slider.value_changed.connect(_on_music_vol_changed)
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	$主面板/ButtonHBox/CloseBtn2.pressed.connect(_on_close)
	visible = false

func open():
	visible = true
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false
	AudioManager.play_music()

func _on_fullscreen_toggled(toggled_on: bool):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_music_vol_changed(val: float):
	AudioManager.set_music_volume(val / 100.0)

func _on_sfx_vol_changed(val: float):
	AudioManager.set_sfx_volume(val / 100.0)

func _on_close():
	close()

func _on_home():
	close()
	get_tree().change_scene_to_file("res://UI/主题/开始界面.tscn")
