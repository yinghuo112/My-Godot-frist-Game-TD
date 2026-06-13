extends Node2D

@onready var toolbar: Control = $UI/Toolbar
@onready var settings_panel: Control = $UI/SettingsPanel
@onready var game_over_bg: ColorRect = $UI/GameOverBG
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var map_manager: MapManager = $MapManager
@onready var wave_config_label: Label = $UI/WaveConfigLabel
@onready var tower_ring: Control = $UI/TowerActionRing
@onready var dialogue_ui: Control = $UI/DialogueUi
@onready var info_plane: PanelContainer = $UI/InfoPlane
@onready var skill_book_plane: PanelContainer = $UI/SkillBookPlane

var tower_types: Array[TowerType] = [
	preload("res://config/Tower_constor/arrow.tres"),
	preload("res://config/Tower_constor/cannon.tres"),
	preload("res://config/Tower_constor/magic.tres"),
	preload("res://config/Tower_constor/mage_tower.tres"),
	preload("res://config/test_tower.tres"),
]
var _build_panel: Panel
var _debug_panel: Control
var _build_buttons: Array[Button] = []
var _pending_slot: TowerSlot = null
const _DEBUG_PANEL_SCENE = preload("res://UI/Debug_panel/debug_panel.tscn")
const _DPS_METER_SCENE = preload("res://UI/panel_dps_meter.tscn")
var _dps_meter: PanelContainer
var _session_id: int = 0
var _last_test_type: String = ""
const _DEBUG_MONSTER_TYPE = preload("res://config/test_enemy.tres")
const _TEST_WAVE_COUNT = 5
const _TEST_WAVE_INTERVAL = 1.27
var _test_wave_remaining: int = 0
var _test_wave_timer: Timer

const _DEBUG_MONSTER_TYPE_2 = preload("res://config/test_enemy_2.tres")
var _test_wave_2_remaining: int = 0
var _test_wave_2_timer: Timer

const _DEBUG_MONSTER_TYPE_3 = preload("res://config/test_enemy_3.tres")
var _test_wave_3_remaining: int = 0
var _test_wave_3_timer: Timer

func _ready() -> void:
	_session_id = _generate_session_id()
	toolbar.wave_start_requested.connect(_on_start_wave)
	toolbar.settings_requested.connect(_on_settings)
	toolbar.debug_requested.connect(_toggle_debug_panel)
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

	_debug_panel = _DEBUG_PANEL_SCENE.instantiate()
	_debug_panel.name = "DebugPanel"
	$UI.add_child(_debug_panel)
	_debug_panel.hide()

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
				var p = md.path_points[i]
				var pos = Vector2(p.x, p.y)
				var pin = Vector2.ZERO
				var pout = Vector2.ZERO
				if i < md.path_points.size() - 1:
					pout = (md.path_points[i + 1] - pos) * 0.3
				if i > 0:
					pin = (md.path_points[i - 1] - pos) * 0.3
				path.curve.add_point(pos, pin, pout)
		map_manager._baked_path_points = path.curve.get_baked_points()
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
	GameManager.reset()
	_update_gold(1000)
	_update_lives(20)
	_update_wave(0)
	AudioManager.play_music()
	map_manager._calculate_play_area()
	print("📂 已加载关卡: %s" % tscn_path)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_toggle_debug_panel()
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_last_test_type = "T(20HP)"
		_spawn_test_enemy()
	if event is InputEventKey and event.pressed and event.keycode == KEY_Y:
		_last_test_type = "Y(40HP)"
		_spawn_test_enemy_2()
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		_last_test_type = "U(1000HP)"
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
		if _debug_panel and _debug_panel.has_method("add_log"):
			_debug_panel.add_log("📝 DPS数据记录中...")
		_dps_meter.dump_to_log(GameManager.wave + 1, _session_id, _last_test_type, _debug_panel)
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

func _toggle_debug_panel() -> void:
	if _debug_panel and _debug_panel.has_method("toggle"):
		_debug_panel.toggle()

func _spawn_test_enemy() -> void:
	if _test_wave_timer.is_stopped():
		_test_wave_remaining = _TEST_WAVE_COUNT
		_test_wave_timer.wait_time = _TEST_WAVE_INTERVAL
		_test_wave_timer.start()
		print("=== 测试波次开始: %d 只, 间隔 %.2fs ===" % [_TEST_WAVE_COUNT, _TEST_WAVE_INTERVAL])
		_spawn_one_test_enemy()

func _on_test_wave_spawn():
	_spawn_one_test_enemy()

func _spawn_one_test_enemy():
	if _test_wave_remaining <= 0:
		_test_wave_timer.stop()
		return
	var debug_type = _DEBUG_MONSTER_TYPE
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	_test_wave_remaining -= 1
	print("测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_remaining, debug_type.max_hp, debug_type.speed])

func _spawn_test_enemy_2() -> void:
	if _test_wave_2_timer.is_stopped():
		_test_wave_2_remaining = _TEST_WAVE_COUNT
		_test_wave_2_timer.wait_time = _TEST_WAVE_INTERVAL
		_test_wave_2_timer.start()
		print("=== 2塔测试波次开始: %d 只, 间隔 %.2fs, HP=40 ===" % [_TEST_WAVE_COUNT, _TEST_WAVE_INTERVAL])
		_spawn_one_test_enemy_2()

func _on_test_wave_2_spawn():
	_spawn_one_test_enemy_2()

func _spawn_one_test_enemy_2():
	if _test_wave_2_remaining <= 0:
		_test_wave_2_timer.stop()
		return
	var debug_type = _DEBUG_MONSTER_TYPE_2
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	_test_wave_2_remaining -= 1
	print("2塔测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_2_remaining, debug_type.max_hp, debug_type.speed])

func _spawn_test_enemy_3() -> void:
	if _test_wave_3_timer.is_stopped():
		_test_wave_3_remaining = _TEST_WAVE_COUNT
		_test_wave_3_timer.wait_time = _TEST_WAVE_INTERVAL
		_test_wave_3_timer.start()
		print("=== 3号测试波次开始: %d 只, 间隔 %.2fs, HP=1000 ===" % [_TEST_WAVE_COUNT, _TEST_WAVE_INTERVAL])
		_spawn_one_test_enemy_3()

func _on_test_wave_3_spawn():
	_spawn_one_test_enemy_3()

func _spawn_one_test_enemy_3():
	if _test_wave_3_remaining <= 0:
		_test_wave_3_timer.stop()
		return
	var debug_type = _DEBUG_MONSTER_TYPE_3
	var enemy = debug_type.scene.instantiate()
	enemy.init(debug_type)
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	_test_wave_3_remaining -= 1
	print("3号测试怪已生成，剩余: %d，血量: %.0f, 速度: %.1f" % [_test_wave_3_remaining, debug_type.max_hp, debug_type.speed])

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
