extends PanelBase

var map_gen_panel: Control
var _selected_path: String = ""

func _ready():
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Dialog/VBox/GenMapBtn.pressed.connect(_on_gen_map)
	$Dialog/VBox/StartBtn.pressed.connect(_on_start)
	$Background.gui_input.connect(_on_bg_clicked)
	visible = false

func populate():
	var list = $Dialog/VBox/LevelScroll/LevelVBox
	for child in list.get_children():
		child.queue_free()

	var dir = DirAccess.open("res://Scene/levels/")
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tscn"):
				var level_name = f.trim_suffix(".tscn")
				var meta_path = "res://data/maps/" + level_name + ".tres"
				var md = load(meta_path) as MapData if ResourceLoader.exists(meta_path) else null
				var display = md.map_name if md and md.map_name != "" else name
				var btn = Button.new()
				btn.text = display
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.pressed.connect(_on_level_selected.bind("res://Scene/levels/" + f))
				list.add_child(btn)
			f = dir.get_next()

	if list.get_child_count() == 0:
		var label = Label.new()
		label.text = "(暂无关卡，请先生成)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list.add_child(label)

	if not map_gen_panel:
		map_gen_panel = $MapGenPanel
	if map_gen_panel:
		map_gen_panel.visible = false
	_selected_path = ""

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

func _on_level_selected(path: String):
	_selected_path = path
	$Dialog/VBox/StartBtn.disabled = false

func _on_start():
	if _selected_path != "":
		get_tree().change_scene_to_file(_selected_path)
