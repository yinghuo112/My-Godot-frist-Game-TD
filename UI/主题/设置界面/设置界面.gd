extends PanelContainer

@onready var fs_btn: CheckButton = $主面板/HBoxContainer/CheckButton
@onready var music_slider: HSlider = $主面板/音量盒/HSlider
@onready var sfx_slider: HSlider = $主面板/音效盒/HSlider
@onready var res_dropdown: OptionButton = $主面板/HBoxContainer/ResolutionDropdown

var resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	fs_btn.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	music_slider.value_changed.connect(_on_music_vol_changed)
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	$主面板/ButtonHBox/CloseBtn2.pressed.connect(_on_close)
	_populate_resolutions()
	res_dropdown.item_selected.connect(_on_resolution_selected)
	visible = false

func open():
	visible = true
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false
	AudioManager.play_music()

func _populate_resolutions():
	res_dropdown.clear()
	var current_size = DisplayServer.window_get_size()
	var select_idx = 0
	for i in resolutions.size():
		var r = resolutions[i]
		res_dropdown.add_item("%d×%d" % [r.x, r.y])
		if r == current_size:
			select_idx = i
	res_dropdown.select(select_idx)

func _on_resolution_selected(idx: int):
	if idx < 0 or idx >= resolutions.size():
		return
	var size = resolutions[idx]
	DisplayServer.window_set_size(size)

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
