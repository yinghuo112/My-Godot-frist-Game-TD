extends Control

var _seed_edit: LineEdit
var _w_spin: SpinBox
var _h_spin: SpinBox
var _style_opt: OptionButton
var _slot_spin: SpinBox

func _ready():
	_seed_edit = $Dialog/VBox/SeedEdit
	_w_spin = $Dialog/VBox/GridW
	_h_spin = $Dialog/VBox/GridH
	_style_opt = $Dialog/VBox/StyleOpt
	_slot_spin = $Dialog/VBox/SlotSpin
	$Dialog/VBox/GenBtn.pressed.connect(_on_generate)
	$Dialog/VBox/CloseBtn.pressed.connect(_on_close)
	$Background.gui_input.connect(_on_bg_click)

func _on_generate():
	var sd = 0
	if _seed_edit.text.strip_edges() != "":
		sd = _seed_edit.text.hash()
	var md = MapData.create_generated(
		"gen_%d" % [Time.get_ticks_usec()],
		"随机地图",
		sd,
		Vector2i(_w_spin.value, _h_spin.value),
		_style_opt.get_item_text(_style_opt.selected)
	)
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
		_seed_edit.text = str(md.seed) if md.seed != 0 else ""
		_w_spin.value = md.grid_size.x
		_h_spin.value = md.grid_size.y
		for i in _style_opt.item_count:
			if _style_opt.get_item_text(i) == md.path_style:
				_style_opt.selected = i
				break
	else:
		_seed_edit.text = ""
		_w_spin.value = 80
		_h_spin.value = 56
		_style_opt.selected = 0