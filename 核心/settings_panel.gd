extends Control

@onready var fs_btn: CheckButton = $Dialog/VBox/FullscreenBtn
@onready var music_slider: HSlider = $Dialog/VBox/MusicVolSlider
@onready var sfx_slider: HSlider = $Dialog/VBox/SfxVolSlider

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	fs_btn.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	music_slider.value_changed.connect(_on_music_vol_changed)
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_clicked)
	visible = false

func open():
	visible = true
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false

func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_close():
	close()

func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_music_vol_changed(val: float):
	AudioManager.set_music_volume(val / 100.0)

func _on_sfx_vol_changed(val: float):
	AudioManager.set_sfx_volume(val / 100.0)
