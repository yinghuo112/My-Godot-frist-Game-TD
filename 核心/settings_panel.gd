extends Control

@onready var fs_btn: CheckButton = $Dialog/VBox/FullscreenBtn
@onready var music_slider: HSlider = $Dialog/VBox/MusicVolSlider
@onready var sfx_slider: HSlider = $Dialog/VBox/SfxVolSlider
@onready var font_dropdown: OptionButton = $Dialog/VBox/FontDropdown

# 初始化设置面板：连接控件信号，同步全屏状态
func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	fs_btn.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	music_slider.value_changed.connect(_on_music_vol_changed)
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_clicked)
	_populate_font_dropdown()
	font_dropdown.item_selected.connect(_on_font_selected)
	visible = false

func _populate_font_dropdown():
	font_dropdown.clear()
	var names = FontManager.get_font_names()
	if names.is_empty():
		font_dropdown.add_item("(无字体)")
		font_dropdown.disabled = true
		return
	for font_name in names:
		font_dropdown.add_item(font_name)
	var current = FontManager.get_current_font()
	if current:
		var idx = names.find(current)
		if idx >= 0:
			font_dropdown.select(idx)

# 打开设置面板并暂停游戏
func open():
	visible = true
	get_tree().paused = true

# 关闭设置面板并恢复游戏
func close():
	visible = false
	get_tree().paused = false

# 点击背景关闭面板
func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

# 点击关闭按钮
func _on_close():
	close()

# 切换全屏模式
func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# 音乐音量滑块变化
func _on_music_vol_changed(val: float):
	AudioManager.set_music_volume(val / 100.0)

# 音效音量滑块变化
func _on_sfx_vol_changed(val: float):
	AudioManager.set_sfx_volume(val / 100.0)

# 字体下拉选择变化
func _on_font_selected(idx: int):
	var font_name = font_dropdown.get_item_text(idx)
	FontManager.apply_font(font_name)
