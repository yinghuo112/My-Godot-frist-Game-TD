extends PanelBase

func _ready():
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_clicked)
	visible = false

func populate():
	$Dialog/VBox/LevelList/NameLabel.text = "关卡 1（默认）"
	$Dialog/VBox/LevelList/StatusLabel.text = "当前选择"

func close():
	visible = false

func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_close():
	close()
