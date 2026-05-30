extends Control

# 初始化关卡选择面板：连接关闭按钮和背景点击事件
func _ready():
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_clicked)
	visible = false

# 填充关卡列表信息
func populate():
	$Dialog/VBox/LevelList/NameLabel.text = "关卡 1（默认）"
	$Dialog/VBox/LevelList/StatusLabel.text = "当前选择"

# 关闭面板
func close():
	visible = false

# 点击背景时关闭面板
func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

# 点击关闭按钮时关闭面板
func _on_close():
	close()
