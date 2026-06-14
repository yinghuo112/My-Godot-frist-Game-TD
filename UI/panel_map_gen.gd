extends Control

var _seed_edit: LineEdit
var _w_spin: SpinBox
var _h_spin: SpinBox
var _style_opt: OptionButton
var _fig_opt: OptionButton
var _slot_spin: SpinBox
var _pw_spin: SpinBox
var _cov_spin: SpinBox

func _ready():
	_seed_edit = $Dialog/VBox/SeedEdit
	_w_spin = $Dialog/VBox/SizeHBox/GridW
	_h_spin = $Dialog/VBox/SizeHBox/GridH
	_style_opt = $Dialog/VBox/StyleOpt
	_fig_opt = $Dialog/VBox/FigureOpt
	_fig_opt.add_item("随机")
	_fig_opt.set_item_metadata(0, "")
	_fig_opt.add_item("分离式")
	_fig_opt.set_item_metadata(1, "split")
	_fig_opt.add_item("交叉式")
	_fig_opt.set_item_metadata(2, "cross")
	_slot_spin = $Dialog/VBox/SlotSpin
	_pw_spin = $Dialog/VBox/PWSpin
	_cov_spin = $Dialog/VBox/CovSpin
	_style_opt.add_item("蛇形")
	_style_opt.set_item_metadata(0, "serpentine")
	_style_opt.add_item("随机漫步")
	_style_opt.set_item_metadata(1, "random_walk")
	_style_opt.add_item("双环路")
	_style_opt.set_item_metadata(2, "figure8")
	_style_opt.item_selected.connect(_on_style_changed)
	_fig_opt.visible = false
	$Dialog/VBox/GenBtn.pressed.connect(_on_generate)
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_click)

func _on_style_changed(idx: int):
	_fig_opt.visible = _style_opt.get_item_metadata(idx) == "figure8"

func _on_generate():
	var sd = 0
	if _seed_edit.text.strip_edges() != "":
		sd = _seed_edit.text.hash()
	var n = MapGenerator.next_map_number()
	var md = MapData.create_generated(
		"map_%03d" % n,
		"地图 #%d" % n,
		sd,
		Vector2i(int(_w_spin.value), int(_h_spin.value)),
		_style_opt.get_item_metadata(_style_opt.selected),
		int(_slot_spin.value),
		int(_pw_spin.value),
		float(_cov_spin.value)
	)
	md.figure8_layout = _fig_opt.get_item_metadata(_fig_opt.selected)
	MapGenerator.pending_gen = md
	_on_close()
	get_tree().change_scene_to_file("res://tower_defense.tscn")

func _on_close():
	visible = false

func _on_bg_click(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()

func populate(md: MapData = null):
	if md:
		_seed_edit.text = str(md.map_seed) if md.map_seed != 0 else ""
		_w_spin.value = md.grid_size.x
		_h_spin.value = md.grid_size.y
		for i in _style_opt.item_count:
			if _style_opt.get_item_metadata(i) == md.path_style:
				_style_opt.selected = i
				break
	else:
		_seed_edit.text = ""
		_w_spin.value = 80
		_h_spin.value = 56
		_pw_spin.value = 2
		_cov_spin.value = 0.3
		_style_opt.selected = 0
