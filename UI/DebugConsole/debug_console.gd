extends Control

const _CONFIG_PATH = "user://debug_settings.cfg"

var _info_overlay: Control
var _map_manager_ref: Node = null
var _test_enemies: Dictionary = {}
var _current_id: String = "test_T"
var _current_enemy: EnemyType = null
var _info_active: bool = false
var _active_tab: String = "test"

var _test_section: VBoxContainer
var _map_section: VBoxContainer
var _enemy_selector: OptionButton
var _hp_input: SpinBox
var _speed_input: SpinBox
var _gold_input: SpinBox
var _phys_armor_input: SpinBox
var _magic_armor_input: SpinBox
var _dodge_input: SpinBox
var _save_status: Label
var _info_btn: Button
var _info_dot: ColorRect
var _tab_test: Button
var _tab_map: Button
var _map_labels: Dictionary = {}

func _ready():
	_build_ui()
	_load_settings()
	visible = false
	call_deferred("_center_panel")

func _center_panel():
	var panel = get_node_or_null("BgPanel")
	if not panel:
		return
	var parent_size = get_rect().size
	panel.position = (parent_size - panel.size) / 2

func _build_ui():
	mouse_filter = Control.MOUSE_FILTER_PASS

	var panel = Panel.new()
	panel.name = "BgPanel"
	var panel_size = Vector2(440, 360)
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.1, 0.1, 0.15, 0.92)
	ps.border_width_left = 1
	ps.border_width_top = 1
	ps.border_width_right = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.3, 0.3, 0.4, 1)
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 12
	vbox.offset_top = 8
	vbox.offset_right = -12
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_title_bar(vbox)
	vbox.add_child(_sep())
	_info_row(vbox)
	vbox.add_child(_sep())
	_tab_bar(vbox)
	vbox.add_child(_sep())

	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	vbox.add_child(content)

	_test_section = _build_test_editor()
	_test_section.visible = false
	content.add_child(_test_section)

	_map_section = _build_map_info()
	_map_section.visible = false
	content.add_child(_map_section)

func _sep() -> HSeparator:
	var s = HSeparator.new()
	s.modulate = Color(1, 1, 1, 0.12)
	return s

func _title_bar(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	var title = Label.new()
	title.text = "调试面板"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hbox.add_child(title)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 0.3, 0.3, 1))
	close_btn.pressed.connect(_on_close)
	hbox.add_child(close_btn)
	parent.add_child(hbox)

func _info_row(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	_info_btn = Button.new()
	_info_btn.text = "信息"
	_info_btn.flat = true
	_info_btn.toggle_mode = true
	_info_btn.add_theme_font_size_override("font_size", 12)
	_info_btn.custom_minimum_size = Vector2(50, 24)
	_info_btn.pressed.connect(_on_info_toggle)
	hbox.add_child(_info_btn)

	_info_dot = ColorRect.new()
	_info_dot.custom_minimum_size = Vector2(8, 8)
	_info_dot.size = Vector2(8, 8)
	_info_dot.color = Color(0.4, 0.4, 0.4, 1)
	hbox.add_child(_info_dot)

	hbox.add_child(Control.new())
	parent.add_child(hbox)

func _tab_bar(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var group = ButtonGroup.new()

	_tab_test = Button.new()
	_tab_test.text = "测试"
	_tab_test.flat = true
	_tab_test.toggle_mode = true
	_tab_test.button_group = group
	_tab_test.custom_minimum_size = Vector2(80, 28)
	var stl = StyleBoxFlat.new()
	stl.bg_color = Color(0.15, 0.15, 0.2, 1)
	stl.border_width_left = 1
	stl.border_width_top = 1
	stl.border_width_bottom = 1
	stl.border_color = Color(0.3, 0.3, 0.4, 1)
	stl.corner_radius_top_left = 4
	stl.corner_radius_bottom_left = 4
	_tab_test.add_theme_stylebox_override("normal", stl)
	var stl_p = StyleBoxFlat.new()
	stl_p.bg_color = Color(0.2, 0.4, 0.7, 1)
	stl_p.border_width_left = 1
	stl_p.border_width_top = 1
	stl_p.border_width_bottom = 1
	stl_p.border_color = Color(0.3, 0.3, 0.4, 1)
	stl_p.corner_radius_top_left = 4
	stl_p.corner_radius_bottom_left = 4
	_tab_test.add_theme_stylebox_override("pressed", stl_p)
	_tab_test.add_theme_stylebox_override("hover_pressed", stl_p)
	_tab_test.pressed.connect(_on_tab_changed.bind("test"))
	hbox.add_child(_tab_test)

	_tab_map = Button.new()
	_tab_map.text = "地图"
	_tab_map.flat = true
	_tab_map.toggle_mode = true
	_tab_map.button_group = group
	_tab_map.custom_minimum_size = Vector2(80, 28)
	var stl2 = StyleBoxFlat.new()
	stl2.bg_color = Color(0.15, 0.15, 0.2, 1)
	stl2.border_width_left = 1
	stl2.border_width_top = 1
	stl2.border_width_right = 1
	stl2.border_width_bottom = 1
	stl2.border_color = Color(0.3, 0.3, 0.4, 1)
	stl2.corner_radius_top_right = 4
	stl2.corner_radius_bottom_right = 4
	_tab_map.add_theme_stylebox_override("normal", stl2)
	var stl2_p = StyleBoxFlat.new()
	stl2_p.bg_color = Color(0.2, 0.4, 0.7, 1)
	stl2_p.border_width_left = 1
	stl2_p.border_width_top = 1
	stl2_p.border_width_right = 1
	stl2_p.border_width_bottom = 1
	stl2_p.border_color = Color(0.3, 0.3, 0.4, 1)
	stl2_p.corner_radius_top_right = 4
	stl2_p.corner_radius_bottom_right = 4
	_tab_map.add_theme_stylebox_override("pressed", stl2_p)
	_tab_map.add_theme_stylebox_override("hover_pressed", stl2_p)
	_tab_map.pressed.connect(_on_tab_changed.bind("map"))
	hbox.add_child(_tab_map)

	parent.add_child(hbox)

func _build_test_editor() -> VBoxContainer:
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

	_hp_input = _sp(0, 99999, 1, 20)
	_speed_input = _sp(0, 9999, 1, 100)
	_gold_input = _sp(0, 9999, 1, 10)
	_phys_armor_input = _sp(0, 1, 0.01, 0)
	_magic_armor_input = _sp(0, 1, 0.01, 0)
	_dodge_input = _sp(0, 1, 0.01, 0)

	for pair in [["HP", _hp_input], ["速度", _speed_input], ["金币", _gold_input], ["物甲", _phys_armor_input], ["魔甲", _magic_armor_input], ["闪避", _dodge_input]]:
		grid.add_child(_fl(pair[0]))
		grid.add_child(pair[1])
	vbox.add_child(grid)

	var bh = HBoxContainer.new()
	bh.add_theme_constant_override("separation", 8)
	var save_btn = Button.new()
	save_btn.text = "写入 CSV"
	save_btn.add_theme_font_size_override("font_size", 11)
	save_btn.pressed.connect(_on_save_csv)
	bh.add_child(save_btn)
	_save_status = Label.new()
	_save_status.add_theme_font_size_override("font_size", 10)
	_save_status.text = ""
	bh.add_child(_save_status)
	bh.add_child(Control.new())
	vbox.add_child(bh)
	return vbox

func _fl(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	l.custom_minimum_size = Vector2(40, 20)
	return l

func _sp(min: float, max: float, step: float, default: float) -> SpinBox:
	var sp = SpinBox.new()
	sp.min_value = min
	sp.max_value = max
	sp.step = step
	sp.value = default
	sp.custom_minimum_size = Vector2(100, 24)
	sp.add_theme_font_size_override("font_size", 11)
	sp.value_changed.connect(_on_field_changed)
	return sp

func _build_map_info() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.name = "MapInfo"
	vbox.add_theme_constant_override("separation", 4)

	var header = Label.new()
	header.text = "当前地图信息"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 0.9))
	vbox.add_child(header)

	var labels = ["name", "seed", "size", "style", "path", "slots", "difficulty", "density", "dps", "dps_per_slot"]
	var keys = ["名称:", "种子:", "尺寸:", "风格:", "路径长:", "塔槽数:", "难度分:", "火力密度:", "总伤害:", "每塔伤害:"]

	for i in labels.size():
		var row = HBoxContainer.new()
		var key = Label.new()
		key.text = keys[i]
		key.add_theme_font_size_override("font_size", 11)
		key.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		key.custom_minimum_size = Vector2(70, 20)
		row.add_child(key)
		var val = Label.new()
		val.name = "V_" + labels[i]
		val.add_theme_font_size_override("font_size", 11)
		val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		row.add_child(val)
		row.add_child(Control.new())
		_map_labels[labels[i]] = val
		vbox.add_child(row)

	return vbox

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

func _apply_info_state():
	_info_btn.button_pressed = _info_active
	_info_dot.color = Color(0.3, 0.8, 0.3, 1) if _info_active else Color(0.4, 0.4, 0.4, 1)
	_info_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1, 1) if _info_active else Color(0.6, 0.6, 0.6, 1))
	if _info_overlay:
		_info_overlay.visible = _info_active

func _apply_tab_state():
	_tab_test.button_pressed = _active_tab == "test"
	_tab_map.button_pressed = _active_tab == "map"
	_test_section.visible = _active_tab == "test"
	_map_section.visible = _active_tab == "map"
	if _active_tab == "map":
		_refresh_map_info()

func _refresh_map_info():
	if not _map_manager_ref:
		_map_manager_ref = get_tree().get_first_node_in_group("map_manager")
	var mm = _map_manager_ref
	if not mm or not mm.current_map_data:
		_set_map_val("name", "无地图")
		return
	var md = mm.current_map_data
	_set_map_val("name", md.map_name if md.map_name != "" else md.map_id)
	_set_map_val("seed", str(md.map_seed))
	_set_map_val("size", "%d×%d" % [md.grid_size.x, md.grid_size.y])
	_set_map_val("style", md.path_style if md.path_style != "" else md.figure8_layout)
	_set_map_val("slots", str(md.slot_positions.size()))

	var diff = MapManager.calc_difficulty(md)
	if diff.has("error"):
		_set_map_val("path", diff.error)
		_set_map_val("difficulty", "-")
		_set_map_val("density", "-")
		_set_map_val("dps", "-")
		_set_map_val("dps_per_slot", "-")
		return
	_set_map_val("path", "%.0fpx" % diff["path_length"])
	_set_map_val("difficulty", "%.1f" % diff["difficulty_score"])
	_set_map_val("density", "%.2f" % diff["fire_density"])

	var dps = MapManager.simulate_dps(md)
	_set_map_val("dps", "%.0f HP" % dps["dps_total"])
	_set_map_val("dps_per_slot", "%.0f HP" % dps["dps_per_slot"])

func _set_map_val(key: String, text: String):
	if key in _map_labels:
		_map_labels[key].text = text

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(_CONFIG_PATH) == OK:
		_info_active = cfg.get_value("debug", "info_overlay", false)
		_active_tab = cfg.get_value("debug", "active_tab", "test")
	_apply_info_state()
	_apply_tab_state()

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("debug", "info_overlay", _info_active)
	cfg.set_value("debug", "active_tab", _active_tab)
	cfg.save(_CONFIG_PATH)

func _on_info_toggle():
	_info_active = not _info_active
	_apply_info_state()
	_save_settings()

func _on_tab_changed(tab: String):
	_active_tab = tab
	_apply_tab_state()
	_save_settings()

func _on_close():
	visible = false
	if _info_overlay:
		_info_overlay.visible = false
	_save_settings()

func refresh_data(e1: EnemyType, e2: EnemyType, e3: EnemyType, info: Control):
	_info_overlay = info
	_apply_info_state()
	_test_enemies = {"test_T": e1, "test_Y": e2, "test_U": e3}
	_enemy_selector.clear()
	for id in _test_enemies.keys():
		_enemy_selector.add_item(id)
	_enemy_selector.select(0)
	_on_enemy_selected(0)
	_apply_tab_state()
