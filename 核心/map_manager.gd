extends Node
class_name MapManager

signal slot_clicked(slot: TowerSlot, is_empty: bool)

const TOWER_SLOT_SCENE = preload("res://Scene/tower_slot.tscn")

var tile_map_layer: TileMapLayer
var enemy_path: Path2D
var enemy_path_2: Path2D

var play_area: Rect2 = Rect2(-1000, -1000, 4000, 4000)
var play_area_margin: float = 100.0

var current_map_data = null
var _baked_path_points: PackedVector2Array = []
var _baked_path_points_2: PackedVector2Array = []
var _path_coverage_cache: Dictionary = {}

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
	if enemy_path and enemy_path.curve:
		_baked_path_points = enemy_path.curve.get_baked_points()
	enemy_path_2 = get_node_or_null("../EnemyPath2")
	if enemy_path_2 and enemy_path_2.curve:
		_baked_path_points_2 = enemy_path_2.curve.get_baked_points()
	_path_coverage_cache.clear()
	_calculate_play_area()
	var default_map = load("res://data/maps/map_001.tres")
	load_map(default_map)

func load_map(data):
	if data == null:
		push_error("load_map: data is null")
		return
	current_map_data = data
	_path_coverage_cache.clear()
	for child in $TowerSlots.get_children():
		child.queue_free()
	for i in data.slot_names.size():
		var slot = TOWER_SLOT_SCENE.instantiate()
		slot.name = data.slot_names[i]
		slot.position = data.slot_positions[i]
		slot.clicked.connect(_on_tower_slot_clicked)
		$TowerSlots.add_child(slot)

func start_tree_spawning(delay: float = 3.0):
	_tree_spawn_timer = Timer.new()
	_tree_spawn_timer.name = "TreeSpawnTimer"
	_tree_spawn_timer.one_shot = true
	_tree_spawn_timer.timeout.connect(_spawn_tree)
	add_child(_tree_spawn_timer)
	_tree_spawn_timer.start(delay)

func get_slots() -> Array[TowerSlot]:
	var result: Array[TowerSlot] = []
	for child in $TowerSlots.get_children():
		if child is TowerSlot:
			result.append(child)
	return result

func get_slot_at(pos: Vector2) -> TowerSlot:
	for slot in get_slots():
		if slot.global_position.distance_squared_to(pos) < CLICK_RADIUS_SQ:
			return slot
	return null

func is_slot_empty(slot: TowerSlot) -> bool:
	return slot.is_empty()

func can_build_at(pos: Vector2) -> bool:
	var slot = get_slot_at(pos)
	return slot != null and is_slot_empty(slot)

func build_tower_at(pos: Vector2, tower_instance: Node2D) -> bool:
	var slot = get_slot_at(pos)
	if not slot or not is_slot_empty(slot):
		return false
	slot.place_tower(tower_instance)
	return true

func free_slot_at(pos: Vector2) -> bool:
	var slot = get_slot_at(pos)
	if not slot:
		return false
	slot.remove_tower()
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
		var tower = slot.get_tower()
		slot_clicked.emit(slot, tower == null)
		return true
	return false

func _on_tower_slot_clicked(slot: TowerSlot, empty: bool):
	slot_clicked.emit(slot, empty)

func count_towers() -> int:
	var count = 0
	for slot in get_slots():
		if not slot.is_empty():
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

func get_enemy_path(route: int = 0) -> Path2D:
	if route == 2 and enemy_path_2:
		return enemy_path_2
	return enemy_path

func get_path_coverage(pos: Vector2, radius: float) -> float:
	var key = "%d_%d_%d" % [pos.x, pos.y, radius]
	if _path_coverage_cache.has(key):
		return _path_coverage_cache[key]
	if _baked_path_points.is_empty():
		return 0.0
	var count = 0
	var radius_sq = radius * radius
	for p in _baked_path_points:
		if pos.distance_squared_to(p) <= radius_sq:
			count += 1
	var result = float(count) / float(_baked_path_points.size()) * 100.0
	_path_coverage_cache[key] = result
	return result

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

static func calc_difficulty(md: MapData) -> Dictionary:
	var base_range = 150.0
	var slot_positions = md.slot_positions
	var waypoints = md.path_points
	var result = {}

	if waypoints.size() < 2:
		result["error"] = "路径点不足"
		return result

	var step = 16.0
	var sampled_path: PackedVector2Array = []
	for i in range(1, waypoints.size()):
		var a = waypoints[i - 1]
		var b = waypoints[i]
		var seg_len = a.distance_to(b)
		var steps = maxi(1, int(seg_len / step))
		for s in range(steps + 1):
			sampled_path.append(a.lerp(b, float(s) / steps))

	var path_length = 0.0
	for i in range(1, waypoints.size()):
		path_length += waypoints[i - 1].distance_to(waypoints[i])

	var range_sq = base_range * base_range
	var total_hits = 0
	var unique_hits = 0

	for sp in sampled_path:
		var hit = false
		for slot_pos in slot_positions:
			if slot_pos.distance_squared_to(sp) <= range_sq:
				total_hits += 1
				if not hit:
					unique_hits += 1
					hit = true

	var total_covered = total_hits * step
	var unique_covered = unique_hits * step
	var avg_per_slot = total_covered / max(slot_positions.size(), 1)
	var fire_density = total_covered / max(unique_covered, 1.0)
	var difficulty = (total_covered / max(path_length, 1.0)) * 100.0

	result["difficulty_score"] = difficulty
	result["path_length"] = path_length
	result["slot_count"] = slot_positions.size()
	result["avg_coverage_per_slot"] = avg_per_slot
	result["fire_density"] = fire_density
	result["path_width"] = md.path_width * 2 + 1
	return result

static func simulate_dps(md: MapData, enemy_speed: float = 100.0) -> Dictionary:
	var base_damage = 5.0
	var base_fire_rate = 1.0
	var base_range = 150.0
	var base_dps = base_damage / base_fire_rate
	var waypoints = md.path_points
	var slot_positions = md.slot_positions
	var step = 16.0
	var range_sq = base_range * base_range

	var total_damage = 0.0
	var path_length = 0.0

	for i in range(1, waypoints.size()):
		var a = waypoints[i - 1]
		var b = waypoints[i]
		var seg_len = a.distance_to(b)
		path_length += seg_len
		var steps = maxi(1, int(seg_len / step))
		for s in range(steps):
			var p = a.lerp(b, float(s) / steps)
			var towers = 0
			for slot_pos in slot_positions:
				if slot_pos.distance_squared_to(p) <= range_sq:
					towers += 1
			var seg_dps = towers * base_dps
			total_damage += seg_dps * (step / enemy_speed)

	var travel_time = path_length / enemy_speed
	return {
		"dps_total": total_damage,
		"dps_per_slot": total_damage / max(slot_positions.size(), 1),
		"kill_threshold_hp": total_damage,
		"travel_time": travel_time,
		"enemy_speed": enemy_speed,
		"base_tower_dps": base_dps
	}

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
