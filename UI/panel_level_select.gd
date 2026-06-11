extends PanelBase

var map_gen_panel: Control

func _ready():
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Dialog/VBox/GenMapBtn.pressed.connect(_on_gen_map)
	$Background.gui_input.connect(_on_bg_clicked)
	visible = false

func populate():
	$Dialog/VBox/LevelList/NameLabel.text = "关卡 1（默认）"
	$Dialog/VBox/LevelList/StatusLabel.text = "当前选择"
	if not map_gen_panel:
		map_gen_panel = $MapGenPanel
	if map_gen_panel:
		map_gen_panel.visible = false

func close():
	visible = false

func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_close():
	close()

func _on_gen_map():
	if map_gen_panel:
		map_gen_panel.populate()
		map_gen_panel.visible = true
