extends Node
class_name MapManager

signal slot_clicked(slot: Marker2D, is_empty: bool)

var tile_map_layer: TileMapLayer
var enemy_path: Path2D

var play_area: Rect2 = Rect2(-1000, -1000, 4000, 4000)
var play_area_margin: float = 100.0

var current_map_data = null
var _occupied_slots: Dictionary = {}

const CLICK_RADIUS_SQ: float = 400.0
const TREE_CLICK_RADIUS_SQ: float = 625.0
const TREE_MARK_COST: int = 10
const MAX_TREES: int = 8
const BLOCK_SLOT_SQ: float = 1600.0
const BLOCK_TREE_SQ: float = 2500.0
const BLOCK_PATH_SQ: float = 1600.0

var tree_scene = preload("res://树/Tree.tscn")
var floating_text_scene = preload("res://工具/FloatingText.tscn")
var _tree_spawn_timer: Timer

func _ready():
	add_to_group("map_manager")
	tile_map_layer = get_node("../TileMapLayer")
	enemy_path = get_node("../EnemyPath")
	_calculate_play_area()
	# 加载默认地图数据
	var default_map = load("res://data/maps/map_001.tres")
	load_map(default_map)

func load_map(data):
	if data == null:
		push_error("load_map: data is null")
		return
	current_map_data = data
	_occupied_slots.clear()
	# 清空旧槽位节点
	for child in $TowerSlots.get_children():
		child.queue_free()
	# 从数据创建槽位 Marker2D
	for i in data.slot_names.size():
		var marker = Marker2D.new()
		marker.name = data.slot_names[i]
		marker.position = data.slot_positions[i]
		$TowerSlots.add_child(marker)

func start_tree_spawning(delay: float = 3.0):
	_tree_spawn_timer = Timer.new()
	_tree_spawn_timer.name = "TreeSpawnTimer"
	_tree_spawn_timer.one_shot = true
	_tree_spawn_timer.timeout.connect(_spawn_tree)
	add_child(_tree_spawn_timer)
	_tree_spawn_timer.start(delay)

func get_slots() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	for child in $TowerSlots.get_children():
		if child is Marker2D:
			result.append(child)
	return result

func get_slot_at(pos: Vector2) -> Marker2D:
	for slot in get_slots():
		if slot.global_position.distance_squared_to(pos) < CLICK_RADIUS_SQ:
			return slot
	return null

func is_slot_empty(slot: Marker2D) -> bool:
	return not _occupied_slots.has(slot.name)

func can_build_at(pos: Vector2) -> bool:
	var slot = get_slot_at(pos)
	return slot != null and is_slot_empty(slot)

func build_tower_at(pos: Vector2, tower_instance: Node2D) -> bool:
	var slot = get_slot_at(pos)
	if not slot or not is_slot_empty(slot):
		return false
	_occupied_slots[slot.name] = tower_instance
	return true

func free_slot_at(pos: Vector2) -> bool:
	var slot = get_slot_at(pos)
	if not slot:
		return false
	_occupied_slots.erase(slot.name)
	return true

func get_slot_difficulty(pos: Vector2) -> float:
	if not current_map_data:
		return 1.0
	for i in current_map_data.slot_positions.size():
		if current_map_data.slot_positions[i].distance_squared_to(pos) < CLICK_RADIUS_SQ:
			return current_map_data.slot_difficulties[i]
	return 1.0

func handle_slot_click(click_pos: Vector2) -> bool:
	var slot = get_slot_at(click_pos)
	if slot:
		slot_clicked.emit(slot, is_slot_empty(slot))
		return true
	return false

func count_towers() -> int:
	var count = 0
	for slot in get_slots():
		if _occupied_slots.has(slot.name):
			count += 1
	return count

func is_position_blocked(pos: Vector2) -> bool:
	for slot in get_slots():
		if slot.global_position.distance_squared_to(pos) < BLOCK_SLOT_SQ:
			return true
	for child in $TreeContainer.get_children():
		if child.global_position.distance_squared_to(pos) < BLOCK_TREE_SQ:
			return true
	if enemy_path and enemy_path.curve:
		var baked = enemy_path.curve.get_baked_points()
		for bp in baked:
			if bp.distance_squared_to(pos) < BLOCK_PATH_SQ:
				return true
	return false

func find_grass_position() -> Vector2:
	var cells = tile_map_layer.get_used_cells()
	cells.shuffle()
	for cell in cells:
		if tile_map_layer.get_cell_source_id(cell) != 0:
			continue
		var world_pos = tile_map_layer.map_to_local(cell)
		if is_position_blocked(world_pos):
			continue
		return world_pos
	return Vector2.ZERO

func handle_tree_click(click_pos: Vector2) -> bool:
	for child in $TreeContainer.get_children():
		if not is_instance_valid(child):
			continue
		if child.global_position.distance_squared_to(click_pos) >= TREE_CLICK_RADIUS_SQ:
			continue
		if child.state != child.State.MATURE:
			_show_floating_text(child.global_position, "树苗成长中...")
			return true
		if child.is_marked:
			child.unmark()
		else:
			if GameManager.can_afford(TREE_MARK_COST):
				GameManager.spend_gold(TREE_MARK_COST)
				child.mark()
			else:
				_show_floating_text(child.global_position, "金币不足...")
		return true
	return false

func get_enemy_path() -> Path2D:
	return enemy_path

func get_tile_map() -> TileMapLayer:
	return tile_map_layer

func _calculate_play_area():
	var cells = tile_map_layer.get_used_cells()
	if cells.is_empty():
		play_area = Rect2(-1000, -1000, 4000, 4000)
		return
	var cell_size = tile_map_layer.tile_set.tile_size
	var min_cell = cells[0]
	var max_cell = cells[0]
	for c in cells:
		min_cell = Vector2i(min(min_cell.x, c.x), min(min_cell.y, c.y))
		max_cell = Vector2i(max(max_cell.x, c.x), max(max_cell.y, c.y))
	var top_left = tile_map_layer.map_to_local(min_cell) - cell_size / 2.0
	var bottom_right = tile_map_layer.map_to_local(max_cell) + cell_size / 2.0
	play_area = Rect2(top_left, bottom_right - top_left).grow(play_area_margin)

func _spawn_tree():
	if $TreeContainer.get_child_count() >= MAX_TREES:
		_tree_spawn_timer.start(5.0)
		return
	var pos = find_grass_position()
	if pos == Vector2.ZERO:
		_tree_spawn_timer.start(3.0)
		return
	var tree = tree_scene.instantiate()
	tree.global_position = pos
	tree.died.connect(_on_tree_died)
	$TreeContainer.add_child(tree)
	_tree_spawn_timer.start(randf_range(8.0, 15.0))

func _on_tree_died(reward: int):
	GameManager.add_gold(reward)

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
