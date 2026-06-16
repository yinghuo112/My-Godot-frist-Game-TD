extends Control

var _info_overlay: Control
var _test_enemies: Dictionary = {}
var _current_id: String = "test_T"
var _current_enemy: EnemyType = null

var _test_section: VBoxContainer
var _enemy_selector: OptionButton
var _hp_input: SpinBox
var _speed_input: SpinBox
var _gold_input: SpinBox
var _phys_armor_input: SpinBox
var _magic_armor_input: SpinBox
var _dodge_input: SpinBox
var _save_status: Label

var _info_btn: Button
var _test_btn: Button
var _test_expanded: bool = false
var _info_active: bool = false

func _ready():
	_build_ui()
	visible = false

func _build_ui():
	mouse_filter = Control.MOUSE_FILTER_PASS

	var panel = Panel.new()
	panel.name = "BgPanel"
	panel.anchors_preset = Control.PRESET_CENTER
	var panel_size = Vector2(440, 340)
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.92)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.3, 0.3, 0.4, 1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 12
	vbox.offset_top = 8
	vbox.offset_right = -12
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_title_bar(vbox)
	vbox.add_child(_make_separator())
	_tool_bar(vbox)
	vbox.add_child(_make_separator())
	_test_section = _test_editor(vbox)
	_test_section.visible = false

func _title_bar(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.name = "TitleBar"
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title = Label.new()
	title.text = "调试面板"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hbox.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 0.3, 0.3, 1))
	close_btn.pressed.connect(_on_close)
	hbox.add_child(close_btn)

	parent.add_child(hbox)

func _tool_bar(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.name = "ToolBar"
	hbox.add_theme_constant_override("separation", 8)

	_info_btn = _make_toggle_btn("信息")
	_info_btn.pressed.connect(_on_info_toggle)
	hbox.add_child(_info_btn)

	_test_btn = _make_toggle_btn("测试")
	_test_btn.pressed.connect(_on_test_toggle)
	hbox.add_child(_test_btn)

	parent.add_child(hbox)

func _make_toggle_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.toggle_mode = true
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.custom_minimum_size = Vector2(60, 24)
	return btn

func _make_separator() -> HSeparator:
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.15)
	return sep

func _test_editor(parent: VBoxContainer) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.name = "TestEditor"
	vbox.add_theme_constant_override("separation", 6)

	var header = Label.new()
	header.text = "测试怪属性"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 0.9))
	vbox.add_child(header)

	var sel_hbox = HBoxContainer.new()
	var sel_label = Label.new()
	sel_label.text = "选择: "
	sel_label.add_theme_font_size_override("font_size", 11)
	sel_hbox.add_child(sel_label)
	_enemy_selector = OptionButton.new()
	_enemy_selector.custom_minimum_size = Vector2(140, 24)
	_enemy_selector.add_theme_font_size_override("font_size", 11)
	_enemy_selector.item_selected.connect(_on_enemy_selected)
	sel_hbox.add_child(_enemy_selector)
	sel_hbox.add_child(Control.new())
	vbox.add_child(sel_hbox)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)

	_hp_input = _make_spin(0, 99999, 1, 20)
	_speed_input = _make_spin(0, 9999, 1, 100)
	_gold_input = _make_spin(0, 9999, 1, 10)
	_phys_armor_input = _make_spin(0, 1, 0.01, 0)
	_magic_armor_input = _make_spin(0, 1, 0.01, 0)
	_dodge_input = _make_spin(0, 1, 0.01, 0)

	grid.add_child(_make_field_label("HP"))
	grid.add_child(_hp_input)
	grid.add_child(_make_field_label("速度"))
	grid.add_child(_speed_input)
	grid.add_child(_make_field_label("金币"))
	grid.add_child(_gold_input)
	grid.add_child(_make_field_label("物甲"))
	grid.add_child(_phys_armor_input)
	grid.add_child(_make_field_label("魔甲"))
	grid.add_child(_magic_armor_input)
	grid.add_child(_make_field_label("闪避"))
	grid.add_child(_dodge_input)

	vbox.add_child(grid)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)

	var save_btn = Button.new()
	save_btn.text = "写入 CSV"
	save_btn.add_theme_font_size_override("font_size", 11)
	save_btn.pressed.connect(_on_save_csv)
	btn_hbox.add_child(save_btn)

	_save_status = Label.new()
	_save_status.add_theme_font_size_override("font_size", 10)
	_save_status.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 1))
	_save_status.text = ""
	btn_hbox.add_child(_save_status)
	btn_hbox.add_child(Control.new())

	vbox.add_child(btn_hbox)

	parent.add_child(vbox)
	return vbox

func _make_field_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	label.custom_minimum_size = Vector2(40, 20)
	return label

func _make_spin(min_val: float, max_val: float, step: float, default: float) -> SpinBox:
	var sp = SpinBox.new()
	sp.min_value = min_val
	sp.max_value = max_val
	sp.step = step
	sp.value = default
	sp.custom_minimum_size = Vector2(100, 24)
	sp.add_theme_font_size_override("font_size", 11)
	sp.value_changed.connect(_on_field_changed)
	return sp

func _on_enemy_selected(idx: int):
	var ids = _test_enemies.keys()
	if idx < 0 or idx >= ids.size():
		return
	_current_id = ids[idx]
	_current_enemy = _test_enemies[_current_id]
	if _current_enemy:
		_hp_input.value = _current_enemy.max_hp
		_speed_input.value = _current_enemy.speed
		_gold_input.value = _current_enemy.gold_reward
		_phys_armor_input.value = _current_enemy.armor_physical
		_magic_armor_input.value = _current_enemy.armor_magic
		_dodge_input.value = _current_enemy.dodge_chance
	_save_status.text = ""

func _on_field_changed(_val):
	if not _current_enemy:
		return
	_current_enemy.max_hp = _hp_input.value
	_current_enemy.speed = _speed_input.value
	_current_enemy.gold_reward = int(_gold_input.value)
	_current_enemy.armor_physical = _phys_armor_input.value
	_current_enemy.armor_magic = _magic_armor_input.value
	_current_enemy.dodge_chance = _dodge_input.value
	_save_status.text = ""

func _on_save_csv():
	CSVLoader.save_enemies("res://data/enemies.csv", _test_enemies)
	_save_status.text = "✓ 已保存"
	_save_status.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 1))

func _on_info_toggle():
	_info_active = not _info_active
	_info_btn.button_pressed = _info_active
	if _info_active:
		_info_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1, 1))
	else:
		_info_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	if _info_overlay:
		_info_overlay.visible = _info_active

func _on_test_toggle():
	_test_expanded = not _test_expanded
	_test_btn.button_pressed = _test_expanded
	_test_section.visible = _test_expanded
	if _test_expanded:
		_test_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1, 1))
	else:
		_test_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

func _on_close():
	visible = false
	_info_active = false
	_info_btn.button_pressed = false
	_info_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_info_btn.add_theme_color_override("font_hover_pressed_color", Color(0.6, 0.6, 0.6, 1))
	_test_expanded = false
	_test_btn.button_pressed = false
	_test_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_test_section.visible = false
	if _info_overlay:
		_info_overlay.visible = false

func refresh_data(e1: EnemyType, e2: EnemyType, e3: EnemyType, info: Control):
	_info_overlay = info
	_test_enemies = {"test_T": e1, "test_Y": e2, "test_U": e3}
	_enemy_selector.clear()
	for id in _test_enemies.keys():
		_enemy_selector.add_item(id)
	_enemy_selector.select(0)
	_on_enemy_selected(0)
