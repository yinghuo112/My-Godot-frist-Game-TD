extends Node2D

@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var start_btn: Button = $UI/HUD/StartWaveBtn
@onready var settings_btn: Button = $UI/HUD/SettingsBtn
@onready var settings_panel: Control = $UI/SettingsPanel
@onready var game_over_bg: ColorRect = $UI/GameOverBG
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var tower_slots: Node2D = $TowerSlots
@onready var wave_config_label: Label = $UI/WaveConfigLabel
@onready var tower_ring: Control = $UI/TowerActionRing
@onready var tree_container: Node2D = $TreeContainer
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var dialogue_ui: Control = $UI/DialogueUi
@onready var info_plane: PanelContainer = $UI/InfoPlane
@onready var skill_book_plane: PanelContainer = $UI/SkillBookPlane

var tower_types: Array[TowerType] = [
	preload("res://resource/Tower_constor/arrow.tres"),
	preload("res://resource/Tower_constor/cannon.tres"),
	preload("res://resource/Tower_constor/magic.tres"),
	preload("res://resource/Tower_constor/mage_tower.tres"),
]
var _build_panel: Panel
var _build_buttons: Array[Button] = []
var _pending_slot: Marker2D = null
var tree_scene = preload("res://树/Tree.tscn")
var floating_text_scene = preload("res://工具/FloatingText.tscn")

const _CLICK_RADIUS_SQ: float = 20.0 * 20.0
const _TREE_CLICK_RADIUS_SQ: float = 25.0 * 25.0
const _TREE_MARK_COST: int = 10
const _MAX_TREES: int = 8
var _tree_spawn_timer: Timer

# 初始化游戏状态，连接信号
func _ready() -> void:
	GameManager.reset()
	start_btn.pressed.connect(_on_start_wave)
	settings_btn.pressed.connect(_on_settings)
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
	if dialogue_ui and dialogue_ui.visible:
		dialogue_ui.connect("dialogue_finished", _setup_tree_spawning)
	else:
		_setup_tree_spawning()

	tower_ring.show_info_requested.connect(_on_tower_info_requested)
	info_plane.closed.connect(_on_info_plane_closed)
	info_plane.skill_book_requested.connect(_on_skill_book_requested)
	skill_book_plane.closed.connect(_on_skill_book_plane_closed)

	# 添加性能调试面板（按 F3 开关）
	var debug = load("res://调试/debug_overlay.gd").new()
	add_child(debug)

	_init_play_area()

# 设置树木生成计时器，3秒后开始生成
func _setup_tree_spawning():
	_tree_spawn_timer = Timer.new()
	_tree_spawn_timer.name = "TreeSpawnTimer"
	_tree_spawn_timer.one_shot = true
	_tree_spawn_timer.timeout.connect(_spawn_tree)
	add_child(_tree_spawn_timer)
	_tree_spawn_timer.start(3.0)


# 输入处理：按键T生成测试敌人，左键点击塔槽或树木
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_spawn_test_enemy()
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		$Camera2D.position = Vector2.ZERO
		$Camera2D.zoom = Vector2(1, 1)
		($Camera2D as Camera2D)._target_zoom = 1.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tower_ring.visible or _build_panel.visible or (dialogue_ui and dialogue_ui.visible) or info_plane.visible or skill_book_plane.visible:
			return
		var click_pos := get_global_mouse_position()
		for slot in tower_slots.get_children():
			if slot is Marker2D:
				if slot.global_position.distance_squared_to(click_pos) < _CLICK_RADIUS_SQ:
					if slot.get_child_count() == 0:
						_show_build_panel(slot)
					else:
						tower_ring.show_for_tower(slot.get_child(0))
					get_viewport().set_input_as_handled()
					return
		# 不是塔槽 → 检查是否点到树
		_click_tree(click_pos)


# InfoPlane 相关
func _on_tower_info_requested(tower: Node2D) -> void:
	info_plane.show_for_tower(tower)

func _on_info_plane_closed() -> void:
	pass

func _on_skill_book_requested(tower: Node2D) -> void:
	skill_book_plane.show_for_tower(tower)

func _on_skill_book_plane_closed() -> void:
	pass

# 未处理的点击：关闭环形菜单和 InfoPlane
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


# 在指定塔槽放置指定类型的防御塔
func _place_tower(slot: Marker2D, tt: TowerType) -> void:
	if not GameManager.can_afford(tt.cost):
		return
	var tower = tt.scene.instantiate()
	tower.init(tt)
	tower.add_to_group("tower")
	slot.add_child(tower)
	tower.position = Vector2.ZERO
	GameManager.spend_gold(tt.cost)

# 初始化建造面板（3个塔按钮）
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

# 在塔槽位置显示建造面板
func _show_build_panel(slot: Marker2D):
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

# 关闭建造面板
func _hide_build_panel():
	_build_panel.hide()
	_pending_slot = null

# 建造面板选择回调
func _on_build_selected(idx: int):
	var slot = _pending_slot
	_hide_build_panel()
	if slot and is_instance_valid(slot) and slot.get_child_count() == 0:
		_place_tower(slot, tower_types[idx])

# 调试功能：按T键直接生成一个测试怪物
func _spawn_test_enemy() -> void:
	print("=== 调试: 直接生成测试小怪 ===")
	var scene = preload("res://怪物/green_monster.tscn")
	var enemy = scene.instantiate()
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	print("测试小怪已生成，路径: EnemyPath")

# 从 TileMapLayer 格子计算可玩区域并存入 GameManager.play_area
func _init_play_area():
	var cells = tile_map_layer.get_used_cells()
	if cells.is_empty():
		GameManager.play_area = Rect2(-1000, -1000, 4000, 4000)
		return
	var ts = tile_map_layer.tile_set
	var cell_size: Vector2 = ts.tile_size
	var min_cell = cells[0]
	var max_cell = cells[0]
	for c in cells:
		min_cell = Vector2i(min(min_cell.x, c.x), min(min_cell.y, c.y))
		max_cell = Vector2i(max(max_cell.x, c.x), max(max_cell.y, c.y))
	var top_left = tile_map_layer.map_to_local(min_cell) - cell_size / 2.0
	var bottom_right = tile_map_layer.map_to_local(max_cell) + cell_size / 2.0
	GameManager.play_area = Rect2(top_left, bottom_right - top_left).grow(100.0)

# 调试：测试怪物死亡回调
func _on_test_enemy_died(enemy):
	print("测试小怪被击杀，金币奖励: %d" % enemy.gold_reward)

# 调试：测试怪物到达终点回调
func _on_test_enemy_reached_end():
	print("测试小怪到达终点")

# ==================== 树系统 ====================

# 在草地格上随机生成一棵树
func _spawn_tree():
	if tree_container.get_child_count() >= _MAX_TREES:
		_tree_spawn_timer.start(5.0)
		return
	var pos = _find_grass_position()
	if pos == Vector2.ZERO:
		_tree_spawn_timer.start(3.0)
		return
	var tree = tree_scene.instantiate()
	tree.global_position = pos
	tree.died.connect(_on_tree_died)
	tree_container.add_child(tree)
	_tree_spawn_timer.start(randf_range(8.0, 15.0))

# 在 TileMap 中寻找未被占用的草地格子
func _find_grass_position() -> Vector2:
	var cells = tile_map_layer.get_used_cells()
	cells.shuffle()
	for cell in cells:
		if tile_map_layer.get_cell_source_id(cell) != 0:
			continue
		var world_pos = tile_map_layer.map_to_local(cell)
		if _is_position_blocked(world_pos):
			continue
		return world_pos
	return Vector2.ZERO

# 检查位置是否被塔槽、其他树木或路径阻挡
func _is_position_blocked(pos: Vector2) -> bool:
	for slot in tower_slots.get_children():
		if slot is Marker2D and slot.global_position.distance_squared_to(pos) < 1600:
			return true
	for child in tree_container.get_children():
		if child.global_position.distance_squared_to(pos) < 2500:
			return true
	var path = $EnemyPath
	var curve = path.curve
	if curve:
		var baked = curve.get_baked_points()
		for bp in baked:
			if bp.distance_squared_to(pos) < 1600:
				return true
	return false

# 处理树木点击：花费金币标记成熟树木，或取消标记
func _click_tree(click_pos: Vector2):
	for child in tree_container.get_children():
		if not is_instance_valid(child):
			continue
		if child.global_position.distance_squared_to(click_pos) >= _TREE_CLICK_RADIUS_SQ:
			continue
		if child.state != child.State.MATURE:
			_show_floating_text(child.global_position, "树苗成长中...")
			return
		if child.is_marked:
			child.unmark()
		else:
			if GameManager.can_afford(_TREE_MARK_COST):
				GameManager.spend_gold(_TREE_MARK_COST)
				child.mark()
			else:
				_show_floating_text(child.global_position, "金币不足...")
		return

# 在世界坐标位置显示浮动提示文字
func _show_floating_text(world_pos: Vector2, msg: String = "金币不足..."):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_pos = viewport_size / 2 + (world_pos - camera.global_position) * camera.zoom
	var ft = floating_text_scene.instantiate()
	ft.position = screen_pos - Vector2(100, 60)
	ft.text = msg
	add_child(ft)

# 树木死亡时获得金币奖励
func _on_tree_died(reward: int):
	GameManager.add_gold(reward)

# 打开设置面板
func _on_settings() -> void:
	settings_panel.open()

# 开始下一波敌人
func _on_start_wave() -> void:
	start_btn.disabled = true
	start_btn.text = "In Progress..."
	GameManager.start_wave()


# 更新金币 UI 显示
func _update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


# 更新生命值 UI 显示
func _update_lives(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount


# 更新波次 UI 显示
func _update_wave(wave: int) -> void:
	wave_label.text = "Wave: %d" % wave


# 波次开始时更新 UI 并播放音效
func _on_wave_started(wave_number: int, count: int, spawn_interval: float) -> void:
	_update_wave(wave_number)
	wave_config_label.text = "Enemies: %d  |  Interval: %.1fs" % [count, spawn_interval]
	AudioManager.play_wave()


# 波次结束后恢复按钮
func _on_wave_done() -> void:
	start_btn.disabled = false
	start_btn.text = "Start Wave"
	wave_config_label.text = ""


# 游戏结束：显示结束画面
func _on_game_over() -> void:
	game_over_bg.visible = true
	game_over_label.visible = true
	start_btn.visible = false
	AudioManager.play_gameover()
