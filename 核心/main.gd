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

var tower_scene = preload("res://scenes/ArrowTower.tscn")
var tree_scene = preload("res://树/Tree.tscn")

const _CLICK_RADIUS_SQ: float = 20.0 * 20.0
const _TREE_CLICK_RADIUS_SQ: float = 25.0 * 25.0
const _MAX_TREES: int = 8
var _tree_spawn_timer: Timer

func _ready() -> void:
	GameManager.reset()
	start_btn.pressed.connect(_on_start_wave)
	settings_btn.pressed.connect(_on_settings)
	GameManager.gold_changed.connect(_update_gold)
	GameManager.lives_changed.connect(_update_lives)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_done.connect(_on_wave_done)
	GameManager.game_over.connect(_on_game_over)
	_update_gold(100)
	_update_lives(20)
	_update_wave(0)
	AudioManager.play_music()
	_setup_tree_spawning()

func _setup_tree_spawning():
	_tree_spawn_timer = Timer.new()
	_tree_spawn_timer.name = "TreeSpawnTimer"
	_tree_spawn_timer.one_shot = true
	_tree_spawn_timer.timeout.connect(_spawn_tree)
	add_child(_tree_spawn_timer)
	_tree_spawn_timer.start(3.0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_spawn_test_enemy()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tower_ring.visible:
			return
		var click_pos := get_global_mouse_position()
		for slot in tower_slots.get_children():
			if slot is Marker2D:
				if slot.global_position.distance_squared_to(click_pos) < _CLICK_RADIUS_SQ:
					if slot.get_child_count() == 0:
						_place_tower(slot)
					else:
						tower_ring.show_for_tower(slot.get_child(0))
					get_viewport().set_input_as_handled()
					return
		# 不是塔槽 → 检查是否点到树
		_click_tree(click_pos)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tower_ring.visible:
			tower_ring.hide_ring()


func _place_tower(slot: Marker2D) -> void:
	if not GameManager.can_afford(50):
		return
	var tower = tower_scene.instantiate()
	tower.add_to_group("tower")
	slot.add_child(tower)
	tower.position = Vector2.ZERO
	GameManager.spend_gold(50)

func _spawn_test_enemy() -> void:
	print("=== 调试: 直接生成测试小怪 ===")
	var scene = preload("res://怪物/green_monster.tscn")
	var enemy = scene.instantiate()
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	print("测试小怪已生成，路径: EnemyPath")

func _on_test_enemy_died(enemy):
	print("测试小怪被击杀，金币奖励: %d" % enemy.gold_reward)

func _on_test_enemy_reached_end():
	print("测试小怪到达终点")

# ==================== 树系统 ====================

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

func _click_tree(click_pos: Vector2):
	for child in tree_container.get_children():
		if not is_instance_valid(child):
			continue
		if child.state != child.State.MATURE:
			continue
		if child.global_position.distance_squared_to(click_pos) < _TREE_CLICK_RADIUS_SQ:
			if child.is_marked:
				child.unmark()
			else:
				child.mark()
			return

func _on_tree_died(reward: int):
	GameManager.add_gold(reward)

func _on_settings() -> void:
	settings_panel.open()

func _on_start_wave() -> void:
	start_btn.disabled = true
	start_btn.text = "In Progress..."
	GameManager.start_wave()


func _update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


func _update_lives(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount


func _update_wave(wave: int) -> void:
	wave_label.text = "Wave: %d" % wave


func _on_wave_started(wave_number: int, count: int, spawn_interval: float) -> void:
	_update_wave(wave_number)
	wave_config_label.text = "Enemies: %d  |  Interval: %.1fs" % [count, spawn_interval]
	AudioManager.play_wave()


func _on_wave_done() -> void:
	start_btn.disabled = false
	start_btn.text = "Start Wave"
	wave_config_label.text = ""


func _on_game_over() -> void:
	game_over_bg.visible = true
	game_over_label.visible = true
	start_btn.visible = false
	AudioManager.play_gameover()
