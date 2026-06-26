extends Node2D

@onready var toolbar: Control = $UI/Toolbar
@onready var settings_panel: Control = $"UI_Overlay/设置界面"
@onready var game_over_bg: ColorRect = $UI_Overlay/GameOverBG
@onready var game_over_label: Label = $UI_Overlay/GameOverLabel
@onready var map_manager: MapManager = $MapManager
@onready var wave_config_label: Label = $UI/WaveConfigLabel
@onready var tower_ring: Control = $UI/TowerActionRing
@onready var dialogue_ui: Control = $UI/DialogueUi
@onready var info_plane: PanelContainer = $UI/InfoPlane
@onready var skill_book_plane: PanelContainer = $UI/SkillBookPlane

var tower_types: Array[TowerType] = []  # 🗼 从 CSV 加载，见 _ready()
var _build_panel: Panel
var _build_buttons: Array[Button] = []
var _pending_slot: TowerSlot = null
const _DEBUG_PANEL_SCENE = preload("res://UI/Debug_panel/debug_panel.tscn")
const _DPS_METER_SCENE = preload("res://UI/panel_dps_meter.tscn")
var _dps_meter: PanelContainer
var _session_id: int = 0
var _last_test_type: String = ""
var _test_enemy: EnemyType
var _test_enemy_2: EnemyType
var _test_enemy_3: EnemyType
var test_wave_count: int = 5
var test_wave_interval: float = 1.27
var test_wave_route: int = 1
var _test_wave_remaining: int = 0
var _test_wave_timer: Timer
var _test_wave_2_remaining: int = 0
var _test_wave_2_timer: Timer
var _test_wave_3_remaining: int = 0
var _test_wave_3_timer: Timer

var _debug_console: Control
var _info_overlay: Control
const _DEBUG_CONSOLE_SCENE = preload("res://UI/DebugConsole/DebugConsole.tscn")

func _ready() -> void:
	var enemies_db = CSVLoader.load_enemies("res://data/enemies.csv")
	_test_enemy = enemies_db.get("test_T")
	_test_enemy_2 = enemies_db.get("test_Y")
	_test_enemy_3 = enemies_db.get("test_U")
	# 🗼 从 CSV 加载塔类型（不再依赖 .tres 文件）
	var towers_db = CSVLoader.load_towers("res://data/towers.csv")
	var tower_ids = ["arrow", "cannon", "magic", "mage_tower", "雪塔", "test_tower"]
	for id in tower_ids:
		if towers_db.has(id):
			tower_types.append(towers_db[id])
		else:
			push_warning("⚠️ 塔类型缺失: %s" % id)
	# 模拟手机视口
	get_window().content_scale_size = Vector2i(960, 540)
	_session_id = _generate_session_id()
	
	_session_id = _generate_session_id()
	toolbar.wave_start_requested.connect(_on_start_wave)
	toolbar.menu_action.connect(_on_menu_action)
	toolbar.route_changed.connect(_on_route_changed)
	GameManager.reset()
	GameManager.gold_changed.connect(_update_gold)
	GameManager.lives_changed.connect(_update_lives)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_done.connect(_on_wave_done)
	GameManager.game_over.connect(_on_game_over)
	_update_gold(1000)
	_update_lives(20)
	_update_wave(0)
	AudioManager.play_music()
	_init_build_panel()
	map_manager.slot_clicked.connect(_on_slot_clicked)
	if MapGenerator.pending_gen:
		_generate_map(MapGenerator.pending_gen)
		MapGenerator.pending_gen = null
	if MapGenerator.pending_level_path != "":
		var lvl_path = MapGenerator.pending_level_path
		MapGenerator.pending_level_path = ""
		_load_level_from_tscn(lvl_path)
	if dialogue_ui and dialogue_ui.visible:
		dialogue_ui.connect("dialogue_finished", map_manager.start_tree_spawning)
	else:
		map_manager.start_tree_spawning()

	tower_ring.show_info_requested.connect(_on_tower_info_requested)
	info_plane.closed.connect(_on_info_plane_closed)
	info_plane.skill_book_requested.connect(_on_skill_book_requested)
	skill_book_plane.closed.connect(_on_skill_book_plane_closed)
	$UI_Overlay/弹窗.link_clicked.connect(_on_popup_link)
	$UI_Overlay/弹窗.popup_closed.connect(_on_popup_closed)

	_info_overlay = _DEBUG_PANEL_SCENE.instantiate()
	_info_overlay.name = "DebugInfoOverlay"
	$UI.add_child(_info_overlay)
	_info_overlay.hide()

	_debug_console = _DEBUG_CONSOLE_SCENE.instantiate()
	_debug_console.name = "DebugConsole"
	_debug_console.hide()
	$UI.add_child(_debug_console)

	_dps_meter = _DPS_METER_SCENE.instantiate()
	_dps_meter.name = "DPSMeter"
	$UI.add_child(_dps_meter)

	MobileAdapter.setup()

	_test_wave_timer = Timer.new()
	_test_wave_timer.name = "TestWaveTimer"
	_test_wave_timer.one_shot = false
	_test_wave_timer.timeout.connect(_on_test_wave_spawn)
	add_child(_test_wave_timer)

	_test_wave_2_timer = Timer.new()
	_test_wave_2_timer.name = "TestWave2Timer"
	_test_wave_2_timer.one_shot = false
	_test_wave_2_timer.timeout.connect(_on_test_wave_2_spawn)
	add_child(_test_wave_2_timer)

	_test_wave_3_timer = Timer.new()
	_test_wave_3_timer.name = "TestWave3Timer"
	_test_wave_3_timer.one_shot = false
	_test_wave_3_timer.timeout.connect(_on_test_wave_3_spawn)
	add_child(_test_wave_3_timer)

func _ensure_logs_dir() -> String:
	var logs_abs = OS.get_user_data_dir().path_join("logs")
	if not DirAccess.dir_exists_absolute(logs_abs):
		DirAccess.make_dir_recursive_absolute(logs_abs)
	return logs_abs

func _generate_session_id() -> int:
	var logs_dir = _ensure_logs_dir()
	var path = logs_dir.path_join("session.txt")
	var id = 1
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		id = int(file.get_line()) + 1
		file.close()
	file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_line(str(id))
		file.close()
	return id

func _generate_map(md: MapData):
	var ts = load("res://data/tileSet/new_tile_set.tres")
	var tilemap = map_manager.tile_map_layer
	var path = map_manager.enemy_path
	if ts and tilemap.tile_set != ts:
		tilemap.tile_set = ts
	var gen = MapGenerator.new()
	gen.generate(tilemap, md)
	map_manager.load_map(md)
	if path:
		path.position = tilemap.position
		path.curve = Curve2D.new()
		if md.path_points.size() >= 2:
			for i in md.path_points.size():
				path.curve.add_point(md.path_points[i], Vector2.ZERO, Vector2.ZERO)
		map_manager._baked_path_points = path.curve.get_baked_points()
	var has_dual = md.alt_path_points.size() >= 2
	if has_dual:
		var path2 = Path2D.new()
		path2.name = "EnemyPath2"
		path2.position = tilemap.position
		path2.curve = Curve2D.new()
		for i in md.alt_path_points.size():
			path2.curve.add_point(md.alt_path_points[i], Vector2.ZERO, Vector2.ZERO)
		add_child(path2)
		map_manager.enemy_path_2 = path2
		map_manager._baked_path_points_2 = path2.curve.get_baked_points()
		toolbar.set_dual_mode(true, md.figure8_layout)
	else:
		toolbar.set_dual_mode(false)
	map_manager._calculate_play_area()

func _load_level_from_tscn(tscn_path: String) -> void:
	var packed = load(tscn_path) as PackedScene
	if not packed:
		push_error("无法加载关卡文件: %s" % tscn_path)
		return
	var inst = packed.instantiate()

	var src_tilemap = inst.get_node("TileMapLayer") as TileMapLayer
	var dst_tilemap = $TileMapLayer
	if src_tilemap and dst_tilemap:
		dst_tilemap.clear()
		dst_tilemap.tile_map_data = src_tilemap.tile_map_data
		dst_tilemap.position = Vector2.ZERO

	var src_enemy_path = inst.get_node("EnemyPath") as Path2D
	var dst_enemy_path = $EnemyPath
	if src_enemy_path and dst_enemy_path and src_enemy_path.curve:
		var nc = Curve2D.new()
		for i in src_enemy_path.curve.point_count:
			nc.add_point(src_enemy_path.curve.get_point_position(i))
		dst_enemy_path.curve = nc
		dst_enemy_path.position = Vector2.ZERO
		map_manager._baked_path_points = nc.get_baked_points()

	var src_enemy_path_2 = inst.get_node_or_null("EnemyPath2") as Path2D
	if src_enemy_path_2 and src_enemy_path_2.curve:
		var nc2 = Curve2D.new()
		for i in src_enemy_path_2.curve.point_count:
			nc2.add_point(src_enemy_path_2.curve.get_point_position(i))
		var dst_path2 = get_node_or_null("EnemyPath2")
		if not dst_path2:
			dst_path2 = Path2D.new()
			dst_path2.name = "EnemyPath2"
			add_child(dst_path2)
		dst_path2.curve = nc2
		dst_path2.position = Vector2.ZERO
		map_manager.enemy_path_2 = dst_path2
		map_manager._baked_path_points_2 = nc2.get_baked_points()

	var md: MapData = null
	var base = tscn_path.get_file().trim_suffix(".tscn")
	var meta_path = "res://data/maps/" + base + ".tres"
	if ResourceLoader.exists(meta_path):
		md = load(meta_path) as MapData
	if not md:
		md = MapData.new()
		md.map_id = base
		md.map_name = base
		var slots_node = inst.get_node("TowerSlots")
		if slots_node:
			for child in slots_node.get_children():
				md.slot_names.append(child.name)
				md.slot_positions.append(child.position)

	inst.queue_free()
	map_manager.load_map(md)
	toolbar.set_dual_mode(md.alt_path_points.size() >= 2, md.figure8_layout)
	GameManager.reset()
	_update_gold(1000)
	_update_lives(20)
	_update_wave(0)
	AudioManager.play_music()
	map_manager._calculate_play_area()
	print("📂 已加载关卡: %s" % tscn_path)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_toggle_console()
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_last_test_type = "T(TestT)"
		_spawn_test_enemy()
	if event is InputEventKey and event.pressed and event.keycode == KEY_Y:
		_last_test_type = "Y(TestY)"
		_spawn_test_enemy_2()
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		_last_test_type = "U(TestU)"
		_spawn_test_enemy_3()
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		$Camera2D.position = Vector2.ZERO
		$Camera2D.zoom = Vector2(1, 1)
		($Camera2D as Camera2D)._target_zoom = 1.0
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		AudioManager.set_sfx_set("1")
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		AudioManager.set_sfx_set("2")
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		AudioManager.set_sfx_set("3")
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		if _info_overlay and _info_overlay.has_method("add_log"):
			_info_overlay.add_log("📝 DPS数据记录中...")
		_dps_meter.dump_to_log(GameManager.wave + 1, _session_id, _last_test_type, _info_overlay)
		_last_test_type = ""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tower_ring.visible or _build_panel.visible or (dialogue_ui and dialogue_ui.visible) or info_plane.visible or skill_book_plane.visible:
			return
		var click_pos := get_global_mouse_position()
		if map_manager.handle_tree_click(click_pos):
			get_viewport().set_input_as_handled()

func _on_slot_clicked(slot: TowerSlot, is_empty: bool):
	if is_empty:
		_show_build_panel(slot)
	else:
		var tower = slot.get_tower()
		if tower:
			tower_ring.show_for_tower(tower)

func _on_tower_info_requested(tower: Node2D) -> void:
	info_plane.show_for_tower(tower)

func _on_info_plane_closed() -> void:
	pass

func _on_skill_book_requested(tower: Node2D) -> void:
	skill_book_plane.show_for_tower(tower)

func _on_skill_book_plane_closed() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _build_panel.visible:
			_hide_build_panel()
		if tower_ring.visible:
			tower_ring.hide_ring()
		if info_plane.visible:
			info_plane.close()
		if skill_book_plane.visible:
			skill_book_plane.close()

func _place_tower(slot: TowerSlot, tt: TowerType) -> void:
	if not GameManager.can_afford(tt.cost):
		return
	var tower = tt.scene.instantiate()
	tower.init(tt)
	tower.add_to_group("tower")
	tower.slot_difficulty = map_manager.get_slot_difficulty(slot.global_position)
	map_manager.build_tower_at(slot.global_position, tower)
	GameManager.spend_gold(tt.cost)
	AudioManager.play("place")

func _init_build_panel():
	_build_panel = Panel.new()
	_build_panel.name = "TowerBuildPanel"
	_build_panel.visible = false
	_build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(_build_panel)
	var vbox = VBoxContainer.new()
	vbox.name = "BtnBox"
	vbox.size = Vector2(140, 0)
	_build_panel.add_child(vbox)
	for i in tower_types.size():
		var btn = Button.new()
		var tt = tower_types[i]
		btn.custom_minimum_size = Vector2(130, 34)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.text = "%s (%dg)" % [tt.display_name, tt.cost]
		btn.pressed.connect(_on_build_selected.bind(i))
		vbox.add_child(btn)
		_build_buttons.append(btn)
	_build_panel.size = Vector2(150, 34 * tower_types.size() + 12)

func _show_build_panel(slot: TowerSlot):
	if _pending_slot:
		return
	_pending_slot = slot
	var camera = get_viewport().get_camera_2d()
	var center = (slot.global_position - camera.global_position) * camera.zoom
	center += get_viewport().get_visible_rect().size / 2
	_build_panel.position = center - Vector2(65, 40)
	for i in tower_types.size():
		_build_buttons[i].disabled = not GameManager.can_afford(tower_types[i].cost)
	_build_panel.show()

func _hide_build_panel():
	_build_panel.hide()
	_pending_slot = null

func _on_build_selected(idx: int):
	var slot = _pending_slot
	_hide_build_panel()
	if slot and is_instance_valid(slot) and map_manager.is_slot_empty(slot):
		_place_tower(slot, tower_types[idx])

func _toggle_console() -> void:
	if not _debug_console:
		return
	_debug_console.visible = not _debug_console.visible
	if _debug_console.visible:
		_debug_console.call("refresh_data", _test_enemy, _test_enemy_2, _test_enemy_3, _info_overlay)

func _spawn_test_enemy() -> void:
	if _test_wave_timer.is_stopped():
		_test_wave_remaining = test_wave_count
		_test_wave_timer.wait_time = test_wave_interval
		_test_wave_timer.start()
		print("=== 测试波次开始: %d 只, 间隔 %.2fs ===" % [test_wave_count, test_wave_interval])
		_spawn_one_test_enemy()

func _on_test_wave_spawn():
	_spawn_one_test_enemy()

func _spawn_one_test_enemy():
	if _test_wave_remaining <= 0:
		_test_wave_timer.stop()
		return
	var debug_type = _test_enemy
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = map_manager.get_enemy_path(test_wave_route)
	path.add_child(enemy)
	_test_wave_remaining -= 1
	print("测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_remaining, debug_type.max_hp, debug_type.speed])

func _spawn_test_enemy_2() -> void:
	if _test_wave_2_timer.is_stopped():
		_test_wave_2_remaining = test_wave_count
		_test_wave_2_timer.wait_time = test_wave_interval
		_test_wave_2_timer.start()
		print("=== 2塔测试波次开始: %d 只, 间隔 %.2fs, HP=40 ===" % [test_wave_count, test_wave_interval])
		_spawn_one_test_enemy_2()

func _on_test_wave_2_spawn():
	_spawn_one_test_enemy_2()

func _spawn_one_test_enemy_2():
	if _test_wave_2_remaining <= 0:
		_test_wave_2_timer.stop()
		return
	var debug_type = _test_enemy_2
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = map_manager.get_enemy_path(test_wave_route)
	path.add_child(enemy)
	_test_wave_2_remaining -= 1
	print("2塔测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_2_remaining, debug_type.max_hp, debug_type.speed])

func _spawn_test_enemy_3() -> void:
	if _test_wave_3_timer.is_stopped():
		_test_wave_3_remaining = test_wave_count
		_test_wave_3_timer.wait_time = test_wave_interval
		_test_wave_3_timer.start()
		print("=== 3号测试波次开始: %d 只, 间隔 %.2fs, HP=1000 ===" % [test_wave_count, test_wave_interval])
		_spawn_one_test_enemy_3()

func _on_test_wave_3_spawn():
	_spawn_one_test_enemy_3()

func _spawn_one_test_enemy_3():
	if _test_wave_3_remaining <= 0:
		_test_wave_3_timer.stop()
		return
	var debug_type = _test_enemy_3
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = map_manager.get_enemy_path(test_wave_route)
	path.add_child(enemy)
	_test_wave_3_remaining -= 1
	print("3号测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_3_remaining, debug_type.max_hp, debug_type.speed])

func _on_menu_action(id: int) -> void:
	match id:
		0:  # ⚙ 设置
			settings_panel.open()
		1:  # 📖 说明
			$UI_Overlay/弹窗.show_popup("📖 按键说明", _get_help_content())
			$UI_Overlay/DimOverlay.show()
		2:  # 🔧 调试
			_toggle_console()
		3:  # 返回主页
			get_window().content_scale_size = Vector2i(1280, 720)
			get_tree().change_scene_to_file("res://UI/主题/开始界面.tscn")
		5:  # ℹ 关于
			$UI_Overlay/弹窗.show_popup("ℹ 关于", _get_about_content())
			$UI_Overlay/DimOverlay.show()

func _get_help_content() -> String:
	return """[center][b]操作说明[/b][/center]
[left]
[color=#ffcc44]左键[/color] 选择/放置塔
[color=#ffcc44]右键[/color] 取消/关闭面板
[color=#ffcc44]滚轮[/color] 缩放地图
[color=#ffcc44]T/U/Y[/color] 调试波次
[color=#ffcc44]F3[/color] 打开调试面板
[color=#ffcc44]P[/color] 暂停
[color=#ffcc44]空格[/color] 开始波次
[/left]"""

func _get_about_content() -> String:
	return """[center][b]塔防游戏[/b][/center]
[center]版本 1.0[/center]
[center][color=#4488ff][url=https://github.com/yinghuo112/My-Godot-frist-Game-TD]GitHub 仓库[/url][/color][/center]"""

func _on_popup_link(url: String) -> void:
	OS.shell_open(url)

func _on_popup_closed() -> void:
	$UI_Overlay/DimOverlay.hide()

func _on_route_changed(route: int) -> void:
	GameManager.current_route = route

func _on_test_enemy_died(enemy):
	print(">>> Debug Monster 被击杀，剩余血量: %.0f / %.0f，金币奖励: %d" % [enemy.current_hp, enemy.max_hp, enemy.gold_reward])

func _on_test_enemy_reached_end():
	print(">>> Debug Monster 到达终点")

func _on_settings() -> void:
	settings_panel.open()

func _on_start_wave() -> void:
	toolbar.set_start_btn_disabled(true)
	toolbar.set_start_btn_text("In Progress...")
	GameManager.start_wave()

func _update_gold(amount: int) -> void:
	toolbar.set_gold(amount)

func _update_lives(amount: int) -> void:
	toolbar.set_lives(amount)

func _update_wave(wave: int) -> void:
	toolbar.set_wave(wave, GameManager.total_waves)

func _on_wave_started(wave_number: int, count: int, spawn_interval: float) -> void:
	_update_wave(wave_number)
	wave_config_label.text = "Enemies: %d  |  Interval: %.1fs" % [count, spawn_interval]
	AudioManager.play_wave()

func _on_wave_done() -> void:
	toolbar.set_start_btn_disabled(false)
	toolbar.set_start_btn_text("Start Wave")
	wave_config_label.text = ""

func _on_game_over() -> void:
	game_over_bg.visible = true
	game_over_label.visible = true
	toolbar.set_start_btn_visible(false)
	AudioManager.play_gameover()
