@tool
extends EditorPlugin

var _dock: Control

func _enter_tree():
	_dock = Control.new()
	_dock.name = "MapPanel"
	add_control_to_bottom_panel(_dock, "地图控制")

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	_dock.add_child(vbox)

	var opt_hbox := HBoxContainer.new()
	opt_hbox.name = "OptionsHBox"
	vbox.add_child(opt_hbox)

	opt_hbox.add_child(Label.new())
	opt_hbox.get_child(-1).text = "草地扩展格数:"

	var spin := SpinBox.new()
	spin.name = "SpinBox"
	spin.min_value = 1
	spin.max_value = 10
	spin.step = 1
	spin.value = 4
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_hbox.add_child(spin)

	opt_hbox.add_child(Label.new())
	opt_hbox.get_child(-1).text = "  种子:"

	var seed_spin := SpinBox.new()
	seed_spin.name = "SeedSpinBox"
	seed_spin.min_value = 0
	seed_spin.max_value = 999999
	seed_spin.step = 1
	seed_spin.value = 0
	seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_hbox.add_child(seed_spin)

	var param_grid := GridContainer.new()
	param_grid.name = "ParamGrid"
	param_grid.columns = 4
	param_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(param_grid)

	param_grid.add_child(Label.new())
	param_grid.get_child(-1).text = "地图宽:"

	var w_spin := SpinBox.new()
	w_spin.name = "MapWSpin"
	w_spin.min_value = 40
	w_spin.max_value = 120
	w_spin.value = 80
	param_grid.add_child(w_spin)

	param_grid.add_child(Label.new())
	param_grid.get_child(-1).text = "地图高:"

	var h_spin := SpinBox.new()
	h_spin.name = "MapHSpin"
	h_spin.min_value = 30
	h_spin.max_value = 80
	h_spin.value = 56
	param_grid.add_child(h_spin)

	param_grid.add_child(Label.new())
	param_grid.get_child(-1).text = "路径半宽:"

	var pw_spin := SpinBox.new()
	pw_spin.name = "PWSpin"
	pw_spin.min_value = 1
	pw_spin.max_value = 5
	pw_spin.value = 2
	param_grid.add_child(pw_spin)

	param_grid.add_child(Label.new())
	param_grid.get_child(-1).text = "覆盖率:"

	var cov_spin := SpinBox.new()
	cov_spin.name = "CovSpin"
	cov_spin.min_value = 0.1
	cov_spin.max_value = 0.6
	cov_spin.step = 0.05
	cov_spin.value = 0.3
	cov_spin.rounded = false
	param_grid.add_child(cov_spin)

	var style_hbox := HBoxContainer.new()
	style_hbox.name = "StyleHBox"
	vbox.add_child(style_hbox)

	style_hbox.add_child(Label.new())
	style_hbox.get_child(-1).text = "路径风格:"

	var style_opt := OptionButton.new()
	style_opt.name = "StyleOpt"
	style_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_opt.add_item("蛇形")
	style_opt.set_item_metadata(0, "serpentine")
	style_opt.add_item("随机漫步")
	style_opt.set_item_metadata(1, "random_walk")
	style_opt.add_item("双环路")
	style_opt.set_item_metadata(2, "figure8")
	style_hbox.add_child(style_opt)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.name = "ButtonHBox"
	vbox.add_child(btn_hbox)

	var expand_btn := Button.new()
	expand_btn.name = "ExpandBtn"
	expand_btn.text = "扩展草地"
	expand_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(expand_btn)

	var clear_btn := Button.new()
	clear_btn.name = "ClearBtn"
	clear_btn.text = "清除草地"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(clear_btn)

	var gen_btn := Button.new()
	gen_btn.name = "GenBtn"
	gen_btn.text = "🎲 生成新地图"
	gen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(gen_btn)

	var info := Label.new()
	info.name = "InfoLabel"
	info.text = "状态：未加载 TileMapLayer"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	vbox.add_child(HSeparator.new())

	var import_label := Label.new()
	import_label.text = "点阵导入（0=草地, 1=路径, 2=塔槽）:"
	vbox.add_child(import_label)

	var import_edit := TextEdit.new()
	import_edit.name = "ImportEdit"
	import_edit.custom_minimum_size = Vector2(0, 120)
	import_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(import_edit)

	var import_btn := Button.new()
	import_btn.name = "ImportBtn"
	import_btn.text = "📥 导入点阵"
	vbox.add_child(import_btn)

	expand_btn.pressed.connect(_on_expand.bind(spin, info))
	clear_btn.pressed.connect(_on_clear.bind(info))
	gen_btn.pressed.connect(_on_generate_map.bind(seed_spin, w_spin, h_spin, pw_spin, cov_spin, style_opt, info))
	import_btn.pressed.connect(_on_import_grid.bind(import_edit, info))

func _exit_tree():
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()

func _on_expand(spin: SpinBox, info: Label):
	var tilemap = find_tilemap()
	if not tilemap:
		return
	var expand = spin.value
	var core_bounds = _get_core_bounds(tilemap)
	if core_bounds.size == Vector2i.ZERO:
		info.text = "错误：未找到路径/塔槽图块"
		return

	var removed := 0
	for cell in tilemap.get_used_cells():
		if tilemap.get_cell_source_id(cell) == 0:
			tilemap.set_cell(cell, -1, Vector2i(-1, -1))
			removed += 1

	var added := 0
	for x in range(core_bounds.position.x - expand, core_bounds.end.x + expand):
		for y in range(core_bounds.position.y - expand, core_bounds.end.y + expand):
			var cell = Vector2i(x, y)
			if tilemap.get_cell_source_id(cell) == -1:
				tilemap.set_cell(cell, 0, Vector2i(0, 0))
				added += 1

	info.text = "移除 %d 块旧草地，新建 %d 块草地（%d 格）" % [removed, added, expand]
	mark_modified()
	_refresh_info(info)

func _on_clear(info: Label):
	var tilemap = find_tilemap()
	if not tilemap:
		return
	var removed := 0
	for cell in tilemap.get_used_cells():
		if tilemap.get_cell_source_id(cell) == 0:
			tilemap.set_cell(cell, -1, Vector2i(-1, -1))
			removed += 1
	info.text = "清除了 %d 块草地" % [removed]
	_refresh_info(info)
	mark_modified()

func _refresh_info(info: Label):
	var tilemap = find_tilemap()
	if not tilemap:
		info.text = "状态：未找到 TileMapLayer"
		return
	var total = tilemap.get_used_cells().size()
	var grass = 0
	var path = 0
	var slot = 0
	for c in tilemap.get_used_cells():
		var sid = tilemap.get_cell_source_id(c)
		match sid:
			0: grass += 1
			1: path += 1
			5: slot += 1
	var core = _get_core_bounds(tilemap)
	if core.size != Vector2i.ZERO:
		info.text = "图块总数: %d  |  草地: %d  路径: %d  塔槽: %d\n核心区域: (%d, %d) - (%d, %d)" % [
			total, grass, path, slot,
			core.position.x, core.position.y, core.end.x, core.end.y]
	else:
		info.text = "图块总数: %d  |  草地: %d  路径: %d  塔槽: %d" % [total, grass, path, slot]

func _on_generate_map(seed_spin: SpinBox, w_spin: SpinBox, h_spin: SpinBox, pw_spin: SpinBox, cov_spin: SpinBox, style_opt: OptionButton, info: Label):
	var ts = load("res://data/tileSet/new_tile_set.tres")
	var n = MapGenerator.next_map_number()
	var style = style_opt.get_item_metadata(style_opt.selected)
	var md = MapData.create_generated("map_%03d" % n, "地图 #%d" % n, int(seed_spin.value), Vector2i(int(w_spin.value), int(h_spin.value)), style, 8, int(pw_spin.value), float(cov_spin.value))
	var tilemap = TileMapLayer.new()
	tilemap.tile_set = ts
	var gen = MapGenerator.new()
	if not gen.generate(tilemap, md):
		info.text = "生成失败"
		return

	seed_spin.value = md.map_seed

	var root = Node2D.new()
	root.name = "GameLevel"
	root.script = load("res://Scene/game_level.gd")
	tilemap.name = "TileMapLayer"
	root.add_child(tilemap)
	tilemap.owner = root

	var enemy_path = Path2D.new()
	enemy_path.name = "EnemyPath"
	enemy_path.position = tilemap.position
	enemy_path.curve = Curve2D.new()
	if md.path_points.size() >= 2:
		for i in md.path_points.size():
			enemy_path.curve.add_point(md.path_points[i])
	root.add_child(enemy_path)
	enemy_path.owner = root

	if md.alt_path_points.size() >= 2:
		var enemy_path_2 = Path2D.new()
		enemy_path_2.name = "EnemyPath2"
		enemy_path_2.position = tilemap.position
		enemy_path_2.curve = Curve2D.new()
		for i in md.alt_path_points.size():
			enemy_path_2.curve.add_point(md.alt_path_points[i])
		root.add_child(enemy_path_2)
		enemy_path_2.owner = root

	var slot_scene = load("res://Scene/tower_slot.tscn")
	var slots_node = Node2D.new()
	slots_node.name = "TowerSlots"
	root.add_child(slots_node)
	slots_node.owner = root
	for i in md.slot_names.size():
		var slot = slot_scene.instantiate()
		slot.name = md.slot_names[i]
		slot.position = md.slot_positions[i]
		slot.add_to_group("interactive_slots")
		slots_node.add_child(slot)
		slot.owner = root

	var tscn_path = "res://Scene/levels/map_%03d.tscn" % n
	var meta_path = "res://data/maps/map_%03d.tres" % n

	var pscene = PackedScene.new()
	var pack_result = pscene.pack(root)
	if pack_result != OK:
		info.text = "打包场景失败：%d" % pack_result
		return

	var save_result = ResourceSaver.save(pscene, tscn_path)
	if save_result != OK:
		info.text = "保存场景失败：%d" % save_result
		return

	md.map_id = "map_%03d" % n
	md.map_name = "地图 #%d" % n
	ResourceSaver.save(md, meta_path)

	EditorInterface.open_scene_from_path(tscn_path)
	info.text = "已保存并打开：%s" % tscn_path.get_file()

func _on_import_grid(import_edit: TextEdit, info: Label):
	var text = import_edit.text.strip_edges()
	if text.is_empty():
		info.text = "错误：请输入点阵数据"
		return
	var ts = load("res://data/tileSet/new_tile_set.tres")
	var md = MapData.create_generated("imported", "导入地图", 0, Vector2i(1, 1), "imported", 0)
	var tilemap = TileMapLayer.new()
	tilemap.tile_set = ts
	if not MapGenerator.import_grid(tilemap, md, text):
		info.text = "导入失败：点阵格式错误或路径不通"
		return

	var root = Node2D.new()
	root.name = "GameLevel"
	root.script = load("res://Scene/game_level.gd")
	tilemap.name = "TileMapLayer"
	root.add_child(tilemap)
	tilemap.owner = root

	var enemy_path = Path2D.new()
	enemy_path.name = "EnemyPath"
	enemy_path.position = tilemap.position
	enemy_path.curve = Curve2D.new()
	if md.path_points.size() >= 2:
		for i in md.path_points.size():
			enemy_path.curve.add_point(md.path_points[i])
	root.add_child(enemy_path)
	enemy_path.owner = root

	if md.alt_path_points.size() >= 2:
		var enemy_path_2 = Path2D.new()
		enemy_path_2.name = "EnemyPath2"
		enemy_path_2.position = tilemap.position
		enemy_path_2.curve = Curve2D.new()
		for i in md.alt_path_points.size():
			enemy_path_2.curve.add_point(md.alt_path_points[i])
		root.add_child(enemy_path_2)
		enemy_path_2.owner = root

	var slot_scene = load("res://Scene/tower_slot.tscn")
	var slots_node = Node2D.new()
	slots_node.name = "TowerSlots"
	root.add_child(slots_node)
	slots_node.owner = root
	for i in md.slot_names.size():
		var slot = slot_scene.instantiate()
		slot.name = md.slot_names[i]
		slot.position = md.slot_positions[i]
		slot.add_to_group("interactive_slots")
		slots_node.add_child(slot)
		slot.owner = root

	var n = MapGenerator.next_map_number()
	var tscn_path = "res://Scene/levels/map_%03d.tscn" % n
	var meta_path = "res://data/maps/map_%03d.tres" % n

	var pscene = PackedScene.new()
	var pack_result = pscene.pack(root)
	if pack_result != OK:
		info.text = "打包场景失败：%d" % pack_result
		return

	var save_result = ResourceSaver.save(pscene, tscn_path)
	if save_result != OK:
		info.text = "保存场景失败：%d" % save_result
		return

	md.map_id = "map_%03d" % n
	md.map_name = "地图 #%d" % n
	ResourceSaver.save(md, meta_path)

	EditorInterface.open_scene_from_path(tscn_path)
	info.text = "已保存并打开：%s" % tscn_path.get_file()

func find_tilemap() -> TileMapLayer:
	var root = get_tree().edited_scene_root
	if not root:
		return null
	return root.get_node_or_null("TileMapLayer") as TileMapLayer

func mark_modified():
	if get_tree().edited_scene_root:
		get_tree().edited_scene_root.scene_file_path = get_tree().edited_scene_root.scene_file_path

func _get_core_bounds(tilemap):
	var core_cells = []
	for c in tilemap.get_used_cells():
		var sid = tilemap.get_cell_source_id(c)
		if sid != 0 and sid != -1:
			core_cells.append(c)
	if core_cells.is_empty():
		return Rect2i(0, 0, 0, 0)
	var min_c = core_cells[0]
	var max_c = core_cells[0]
	for c in core_cells:
		min_c = Vector2i(min(min_c.x, c.x), min(min_c.y, c.y))
		max_c = Vector2i(max(max_c.x, c.x), max(max_c.y, c.y))
	return Rect2i(min_c, max_c - min_c + Vector2i(1, 1))
