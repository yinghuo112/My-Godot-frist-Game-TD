@tool
extends RefCounted
class_name MapGenerator

# ========================================
# MapGenerator —— 地图生成器
# ========================================
# 核心数据结构：
#   内部点阵 _grid: PackedByteArray（0=草地, 1=路径, 2=塔槽）
#
# 路径算法：
#   蛇形/随机漫步路径算法
#
# 塔槽放置：
#   2x2 塔槽放置 + 间距/重叠检测
#
# 渲染流程：
#   渲染到 TileMapLayer（三层：草地底→路径→塔槽 2x2）
#
# 输出：
#   输出到 MapData（md.tile_data, md.path_points, md.slot_positions）
# ========================================

static var pending_gen: MapData = null
static var pending_level_path: String = ""

static func next_map_number() -> int:
	var max_n = 0
	var re = RegEx.new()
	re.compile("^map_(\\d+)\\.tscn$")
	var dir = DirAccess.open("res://Scene/levels")
	if dir:
		for f in dir.get_files():
			var m = re.search(f)
			if m:
				var n = int(m.get_string(1))
				if n > max_n:
					max_n = n
	return max_n + 1

# 点阵值常量
const MARK_GRASS = 0
const MARK_PATH = 1
const MARK_SLOT = 2

# TileSet Source ID（对应 new_tile_set.tres）
const SOURCE_ID_GRASS = 0
const SOURCE_ID_PATH  = 1
const SOURCE_ID_SLOT  = 5

# 图块默认坐标
const ATLAS_COORD = Vector2i(0, 0)

var _path_w: int = 2
var _coverage: float = 0.3
var _rng: RandomNumberGenerator
var _grid: PackedByteArray
var _w: int
var _h: int
var _tilemap: TileMapLayer
var _tile_size_half: Vector2

# ========================================
# 算法生成入口
# ========================================
func generate(tilemap: TileMapLayer, md: MapData) -> bool:
	_tilemap = tilemap
	_rng = RandomNumberGenerator.new()
	if md.map_seed == 0:
		md.map_seed = _rng.randi()
	_rng.seed = md.map_seed
	_w = md.grid_size.x
	_h = md.grid_size.y
	_path_w = md.path_width
	_coverage = md.path_coverage
	_tile_size_half = tilemap.tile_set.tile_size * 0.5

	_grid = PackedByteArray()
	_grid.resize(_w * _h)
	_grid.fill(MARK_GRASS)

	var pts = _gen_path(md)
	if pts.is_empty():
		return false

	_generate_slots_data(pts, md)

	_render_to_tilemap(pts, md)
	return true

# ========================================
# 点阵导入入口（从 2D 数组加载预设地图）
# ========================================
# grid_text: 逗号/空格分隔的文本矩阵
#   0 = 草地, 1 = 路径, 2 = 塔槽锚点（2x2 左上角）
#   示例：
#   0,0,0,0,0,0
#   0,1,1,1,0,0
#   0,0,0,1,2,0
#   0,0,0,1,0,0
#   0,2,0,0,0,0
# ========================================
static func import_grid(tilemap: TileMapLayer, md: MapData, grid_text: String) -> bool:
	var grid = _parse_grid_text(grid_text)
	if grid.is_empty() or grid[0].is_empty():
		return false
	var h = grid.size()
	var w = grid[0].size()

	# 转换为 PackedByteArray
	var grid_data = PackedByteArray()
	grid_data.resize(w * h)
	grid_data.fill(MARK_GRASS)
	for y in range(h):
		for x in range(mini(grid[y].size(), w)):
			var v = grid[y][x]
			if v != MARK_GRASS and v != MARK_PATH and v != MARK_SLOT:
				v = MARK_GRASS
			grid_data[y * w + x] = v

	# 从点阵提取路径点
	var pts = _extract_path_from_grid(grid_data, w, h)
	if pts.is_empty():
		return false

	# 提取塔槽位置
	var slot_names: Array[String] = []
	var slot_positions: Array[Vector2] = []
	var slot_diffs: Array[float] = []
	var tsh = tilemap.tile_set.tile_size * 0.5
	var slot_idx = 0
	for y in range(h):
		for x in range(w):
			if grid_data[y * w + x] == MARK_SLOT:
				var wp = tilemap.map_to_local(Vector2i(x, y)) + tsh
				slot_names.append("Slot%d" % (slot_idx + 1))
				slot_positions.append(wp)
				slot_diffs.append(1.0)
				slot_idx += 1

	md.grid_size = Vector2i(w, h)
	md.path_style = "imported"
	md.tile_data = grid_data

	var cell_path = PackedVector2Array()
	for p in pts:
		cell_path.append(tilemap.map_to_local(Vector2i(p.x, p.y)))
	md.path_points = cell_path

	md.slot_names = slot_names
	md.slot_positions = slot_positions
	md.slot_difficulties = slot_diffs

	_render_grid(tilemap, grid_data, w, h)
	return true

# ========================================
# 解析文本点阵 → 二维 int 数组
# ========================================
static func _parse_grid_text(text: String) -> Array[Array]:
	var rows = text.strip_edges().split("\n")
	var result: Array[Array] = []
	for line in rows:
		line = line.strip_edges()
		if line.is_empty():
			continue
		line = line.replace("[", "").replace("]", "")
		var parts = line.split(",") if "," in line else line.split(" ")
		var row: Array[int] = []
		for p in parts:
			p = p.strip_edges()
			if not p.is_empty():
				row.append(int(p))
		if not row.is_empty():
			result.append(row)
	return result

# ========================================
# 从点阵提取路径点序列
# ========================================
static func _extract_path_from_grid(grid_data: PackedByteArray, w: int, h: int) -> Array[Vector2i]:
	var path_cells: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if grid_data[y * w + x] == MARK_PATH:
				path_cells.append(Vector2i(x, y))
	if path_cells.is_empty():
		return []

	var neighbors: Dictionary = {}
	for cell in path_cells:
		var nbs: Array[Vector2i] = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb = cell + d
			if nb.x >= 0 and nb.x < w and nb.y >= 0 and nb.y < h and grid_data[nb.y * w + nb.x] == MARK_PATH:
				nbs.append(nb)
		neighbors[cell] = nbs

	var start: Vector2i = path_cells[0]
	for cell in path_cells:
		if neighbors[cell].size() == 1:
			start = cell
			break

	var ordered: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var current = start
	for _i in range(path_cells.size() * 2):
		var found = false
		for nb in neighbors[current]:
			if not visited.has(nb):
				ordered.append(nb)
				visited[nb] = true
				current = nb
				found = true
				break
		if not found:
			break

	if ordered.size() <= 2:
		return ordered

	var compressed: Array[Vector2i] = [ordered[0]]
	var prev_dir = ordered[1] - ordered[0]
	for i in range(2, ordered.size()):
		var dir = ordered[i] - ordered[i - 1]
		if dir != prev_dir:
			compressed.append(ordered[i - 1])
			prev_dir = dir
	compressed.append(ordered[-1])
	return compressed

# ========================================
# 渲染点阵到 TileMapLayer
# ========================================
static func _render_grid(tilemap: TileMapLayer, grid_data: PackedByteArray, w: int, h: int):
	tilemap.clear()
	for y in range(h):
		for x in range(w):
			tilemap.set_cell(Vector2i(x, y), SOURCE_ID_GRASS, ATLAS_COORD, 0)

	for y in range(h):
		for x in range(w):
			var cell = Vector2i(x, y)
			var mark = grid_data[y * w + x]
			if mark == MARK_PATH:
				tilemap.set_cell(cell, SOURCE_ID_PATH, ATLAS_COORD, 0)
			elif mark == MARK_SLOT:
				for ox in range(2):
					for oy in range(2):
						var tc = cell + Vector2i(ox, oy)
						if tc.x >= 0 and tc.x < w and tc.y >= 0 and tc.y < h:
							tilemap.set_cell(tc, SOURCE_ID_SLOT, Vector2i(ox, oy), 0)

# ========================================
# 通用渲染（算法生成也用这个）
# ========================================
func _render_to_tilemap(pts: Array[Vector2i], md: MapData):
	_tilemap.clear()
	for y in range(_h):
		for x in range(_w):
			_tilemap.set_cell(Vector2i(x, y), SOURCE_ID_GRASS, ATLAS_COORD, 0)

	for y in range(_h):
		for x in range(_w):
			var cell = Vector2i(x, y)
			var mark = _grid[y * _w + x]
			if mark == MARK_PATH:
				_tilemap.set_cell(cell, SOURCE_ID_PATH, ATLAS_COORD, 0)

	for y in range(_h):
		for x in range(_w):
			var cell = Vector2i(x, y)
			var mark = _grid[y * _w + x]
			if mark == MARK_SLOT:
				for ox in range(2):
					for oy in range(2):
						var target_cell = cell + Vector2i(ox, oy)
						if _inb(target_cell):
							_tilemap.set_cell(target_cell, SOURCE_ID_SLOT, Vector2i(ox, oy), 0)

	if md.alt_path_points.size() > 0:
		var alt_world = PackedVector2Array()
		for i in range(md.alt_path_points.size()):
			var gp = md.alt_path_points[i]
			alt_world.append(_tilemap.map_to_local(Vector2i(gp.x, gp.y)))
		md.alt_path_points = alt_world

	var cell_path = PackedVector2Array()
	for p in pts:
		cell_path.append(_tilemap.map_to_local(Vector2i(p.x, p.y)))
	md.path_points = cell_path
	md.tile_data = _grid

# ========================================
# 点阵读写辅助
# ========================================
func _gv(cell: Vector2i) -> int:
	return _grid[cell.y * _w + cell.x]

func _sv(cell: Vector2i, v: int):
	_grid[cell.y * _w + cell.x] = v

func _inb(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _w and cell.y >= 0 and cell.y < _h

# ========================================
# 路径刻画（5 格宽走廊）
# ========================================
func _carve_h(x1: int, x2: int, y: int, skip_existing: bool = false):
	var lo = mini(x1, x2)
	var hi = maxi(x1, x2)
	for x in range(lo, hi + 1):
		for wy in range(-_path_w, _path_w + 1):
			var c = Vector2i(x, y + wy)
			if _inb(c) and not (skip_existing and _gv(c) == MARK_PATH):
				_sv(c, MARK_PATH)

func _carve_v(y1: int, y2: int, x: int, skip_existing: bool = false):
	var lo = mini(y1, y2)
	var hi = maxi(y1, y2)
	for y in range(lo, hi + 1):
		for wx in range(-_path_w, _path_w + 1):
			var c = Vector2i(x + wx, y)
			if _inb(c) and not (skip_existing and _gv(c) == MARK_PATH):
				_sv(c, MARK_PATH)

# ========================================
# 路径算法分发
# ========================================
func _gen_path(md: MapData) -> Array[Vector2i]:
	match md.path_style:
		"random_walk": return _gen_random_walk()
		"figure8": return _gen_figure8(md)
	return _gen_serpentine()

# ========================================
# 蛇形路径
# ========================================
func _calc_segments() -> int:
	var target_cells = _w * _h * _coverage
	var per_seg = (_w / 6.0 + _h * 0.275) * (2 * _path_w + 1)
	var segs = ceili(target_cells / per_seg) if per_seg > 0 else 4
	return clampi(segs, 2, 10)

func _gen_serpentine() -> Array[Vector2i]:
	var margin = 2 * _path_w + 2
	var ey = _h / 2 + _rng.randi_range(-_h / 6, _h / 6)
	ey = clampi(ey, margin, _h - margin - 1)
	var ex = _h / 2 + _rng.randi_range(-_h / 6, _h / 6)
	ex = clampi(ex, margin, _h - margin - 1)
	var segs = _calc_segments()
	var seg_w = _w / (segs + 1)
	var pts: Array[Vector2i] = []
	pts.append(Vector2i(0, ey))
	var cy = ey
	var dy = 1
	for i in range(segs):
		var tx = seg_w * (i + 1) + _rng.randi_range(-seg_w / 3, seg_w / 3)
		tx = clampi(tx, margin, _w - margin - 1)
		var ry = _h * _rng.randf_range(0.2, 0.35)
		var ty = cy + dy * ry
		ty = clampi(ty, margin, _h - margin - 1)
		_carve_h(pts[-1].x, tx, cy)
		pts.append(Vector2i(tx, cy))
		_carve_v(cy, ty, tx)
		cy = ty
		dy *= -1
		pts.append(Vector2i(tx, cy))
	_carve_h(pts[-1].x, _w - 1, cy)
	pts.append(Vector2i(_w - 1, cy))
	_carve_v(cy, ex, _w - 1)
	pts.append(Vector2i(_w - 1, ex))
	return pts

# ========================================
# 随机漫步路径
# ========================================
func _gen_random_walk() -> Array[Vector2i]:
	var cx = _rng.randi_range(_path_w + 1, _w - _path_w - 2)
	var cy = _rng.randi_range(_path_w + 1, _h - _path_w - 2)
	var pts: Array[Vector2i] = [Vector2i(cx, cy)]
	var steps = _rng.randi_range(_h * 2, _h * 3)
	var dirs = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for _i in range(steps):
		var d = dirs[_rng.randi_range(0, 3)]
		var nx = cx + d.x
		var ny = cy + d.y
		if not _inb(Vector2i(nx, ny)):
			continue
		if _gv(Vector2i(nx, ny)) == MARK_PATH:
			continue
		cx = nx
		cy = ny
		_sv(Vector2i(cx, cy), MARK_PATH)
		for wx in range(-_path_w, _path_w + 1):
			for wy in range(-_path_w, _path_w + 1):
				var n = Vector2i(cx + wx, cy + wy)
				if _inb(n):
					_sv(n, MARK_PATH)
		if _i % 20 == 0:
			pts.append(Vector2i(cx, cy))
	if pts.size() < 3:
		return _gen_serpentine()
	return pts

# ========================================
# 双环路 — 提供 2 条独立怪物路线
# ========================================
# 布局随机：分离式（两条环路独立入口/出口）或交叉式（共享入口，中心分岔）
# ========================================
func _gen_figure8(md: MapData) -> Array[Vector2i]:
	var margin = 2 * _path_w + 2
	var cx = _w / 2 + _rng.randi_range(-_w / 10, _w / 10)
	cx = clampi(cx, _w / 4, _w * 3 / 4)
	var cy = _h / 2 + _rng.randi_range(-_h / 10, _h / 10)
	cy = clampi(cy, margin + 2, _h - margin - 2)
	var rx = maxi(1, _rng.randi_range(_w / 6, _w / 4))
	var ry = maxi(1, _rng.randi_range(_h / 6, _h / 4))

	var layout = md.figure8_layout
	if layout != "split" and layout != "cross":
		layout = "split" if _rng.randi() % 2 == 0 else "cross"
	md.figure8_layout = layout

	var raw_primary: Array[Vector2i]
	var raw_alt: Array[Vector2i]

	if layout == "split":
		var uy = clampi(cy - ry, margin + 1, _h - margin - 1)
		var ly = clampi(cy + ry, margin + 1, _h - margin - 1)
		raw_primary = [
			Vector2i(0, uy), Vector2i(cx - rx, uy), Vector2i(cx + rx, uy),
			Vector2i(cx + rx, uy - ry), Vector2i(cx - rx, uy - ry),
			Vector2i(cx - rx, uy), Vector2i(_w - 1, uy)]
		raw_alt = [
			Vector2i(0, ly), Vector2i(cx - rx, ly), Vector2i(cx + rx, ly),
			Vector2i(cx + rx, ly + ry), Vector2i(cx - rx, ly + ry),
			Vector2i(cx - rx, ly), Vector2i(_w - 1, ly)]
	else:
		raw_primary = [
			Vector2i(0, cy), Vector2i(cx, cy),
			Vector2i(cx + rx, cy), Vector2i(cx + rx, cy - ry),
			Vector2i(cx - rx, cy - ry), Vector2i(cx - rx, cy),
			Vector2i(_w - 1, cy)]
		raw_alt = [
			Vector2i(0, cy), Vector2i(cx, cy),
			Vector2i(cx + rx, cy), Vector2i(cx + rx, cy + ry),
			Vector2i(cx - rx, cy + ry), Vector2i(cx - rx, cy),
			Vector2i(_w - 1, cy)]

	for i in range(raw_primary.size()):
		raw_primary[i] = Vector2i(clampi(raw_primary[i].x, margin, _w - margin - 1), clampi(raw_primary[i].y, margin, _h - margin - 1))
	for i in range(raw_alt.size()):
		raw_alt[i] = Vector2i(clampi(raw_alt[i].x, margin, _w - margin - 1), clampi(raw_alt[i].y, margin, _h - margin - 1))

	var pts_primary = _build_carved_path(raw_primary)
	var pts_alt = _build_carved_path(raw_alt, true)

	var alt_raw = PackedVector2Array()
	for p in pts_alt:
		alt_raw.append(Vector2(p.x, p.y))
	md.alt_path_points = alt_raw

	return pts_primary

func _build_carved_path(raw: Array[Vector2i], skip_existing: bool = false) -> Array[Vector2i]:
	var pts: Array[Vector2i] = [raw[0]]
	for i in range(1, raw.size()):
		var p0 = pts[-1]
		var p1 = raw[i]
		if p0.x == p1.x or p0.y == p1.y:
			pts.append(p1)
		else:
			pts.append(Vector2i(p1.x, p0.y))
			pts.append(p1)
	for i in range(1, pts.size()):
		var p0 = pts[i - 1]
		var p1 = pts[i]
		if p0.y == p1.y:
			_carve_h(p0.x, p1.x, p0.y, skip_existing)
		else:
			_carve_v(p0.y, p1.y, p0.x, skip_existing)
	var compressed: Array[Vector2i] = [pts[0]]
	var prev_dir = pts[1] - pts[0]
	for i in range(2, pts.size()):
		var dir = pts[i] - pts[i - 1]
		if dir != prev_dir:
			compressed.append(pts[i - 1])
			prev_dir = dir
	compressed.append(pts[-1])
	return compressed

# ========================================
# 自动塔槽放置（仅算法生成使用）
# ========================================
func _generate_slots_data(pts: Array[Vector2i], md: MapData):
	var n = md.slot_count
	var spacing = maxi(1, pts.size() / (n + 1))
	var names: Array[String] = []
	var positions: Array[Vector2] = []
	var diffs: Array[float] = []
	var taken: Array[Vector2i] = []

	for i in range(n):
		var idx = spacing * (i + 1)
		if idx >= pts.size(): break

		var pp = pts[idx]
		var dir = Vector2i.ZERO
		if idx > 0 and idx < pts.size() - 1:
			dir = pts[idx + 1] - pts[idx - 1]
		else:
			dir = Vector2i.RIGHT

		var perp = Vector2(-dir.y, dir.x).normalized()

		var sp = Vector2i.ZERO
		for dist in [4.0, 3.0, 5.0, 6.0, 7.0, 8.0]:
			for side in [1, -1]:
				var cand = pp + Vector2i(perp * dist * side)

				# 检查 2x2 区域全是草地
				var can_fit_2x2 = true
				for ox in range(2):
					for oy in range(2):
						var building_cell = cand + Vector2i(ox, oy)
						if not _inb(building_cell) or _gv(building_cell) != MARK_GRASS:
							can_fit_2x2 = false
							break
					if not can_fit_2x2: break

				if can_fit_2x2:
					# 检查路径间距（距路径至少 1 格）
					var safe_margin = true
					for ox in range(-1, 3):
						for oy in range(-1, 3):
							var check_cell = cand + Vector2i(ox, oy)
							if _inb(check_cell) and _gv(check_cell) == MARK_PATH:
								safe_margin = false
								break
						if not safe_margin: break

					if not safe_margin: continue

					# 检查槽位间距（槽位之间至少 4 格距离平方）
					var overlapping = false
					for t in taken:
						if t.distance_squared_to(cand) < 16:
							overlapping = true
							break
					if not overlapping:
						sp = cand
						break
			if sp != Vector2i.ZERO: break

		if sp == Vector2i.ZERO: continue

		taken.append(sp)
		_sv(sp, MARK_SLOT)

		var center_wp = _tilemap.map_to_local(sp) + _tile_size_half

		names.append("Slot%d" % (positions.size() + 1))
		positions.append(center_wp)
		diffs.append(lerpf(1.0, 1.5, float(positions.size()) / n))

	md.slot_names = names
	md.slot_positions = positions
	md.slot_difficulties = diffs
