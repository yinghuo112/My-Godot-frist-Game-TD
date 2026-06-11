extends RefCounted
class_name MapGenerator

static var pending_gen: MapData = null

const SRC_GRASS = 0
const SRC_PATH = 1
const SRC_WALL = 2

const PATH_W = 2
const MIN_GAP = 4
const BORDER = 3

var _rng: RandomNumberGenerator
var _grid: PackedByteArray
var _w: int
var _h: int
var _tilemap: TileMapLayer

func generate(tilemap: TileMapLayer, md: MapData) -> bool:
	_tilemap = tilemap
	_rng = RandomNumberGenerator.new()
	if md.seed == 0:
		md.seed = randi()
	_rng.seed = md.seed
	_w = md.grid_size.x
	_h = md.grid_size.y
	_grid = PackedByteArray()
	_grid.resize(_w * _h)
	_grid.fill(SRC_GRASS)
	var pts = _gen_path(md)
	if pts.is_empty():
		return false
	_add_obstacles()
	tilemap.clear()
	for y in range(_h):
		for x in range(_w):
			var sid = _grid[y * _w + x]
			if sid != SRC_GRASS:
				tilemap.set_cell(Vector2i(x, y), sid, Vector2i(0, 0), 0)
	_generate_slots(pts, md)
	var cell_path = PackedVector2Array()
	for p in pts:
		cell_path.append(tilemap.map_to_local(Vector2i(p.x, p.y)))
	md.path_points = cell_path
	md.tile_data = _grid
	return true

func _gv(cell: Vector2i) -> int:
	return _grid[cell.y * _w + cell.x]

func _sv(cell: Vector2i, v: int):
	_grid[cell.y * _w + cell.x] = v

func _inb(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _w and cell.y >= 0 and cell.y < _h

func _carve_h(x1: int, x2: int, y: int):
	var lo = mini(x1, x2)
	var hi = maxi(x1, x2)
	for x in range(lo, hi + 1):
		for wy in range(-PATH_W, PATH_W + 1):
			var c = Vector2i(x, y + wy)
			if _inb(c):
				_sv(c, SRC_PATH)

func _carve_v(y1: int, y2: int, x: int):
	var lo = mini(y1, y2)
	var hi = maxi(y1, y2)
	for y in range(lo, hi + 1):
		for wx in range(-PATH_W, PATH_W + 1):
			var c = Vector2i(x + wx, y)
			if _inb(c):
				_sv(c, SRC_PATH)

func _gen_path(md: MapData) -> Array[Vector2i]:
	match md.path_style:
		"random_walk": return _gen_random_walk()
	return _gen_serpentine()

func _gen_serpentine() -> Array[Vector2i]:
	var ey = _h / 2 + _rng.randi_range(-_h / 6, _h / 6)
	ey = clampi(ey, BORDER + PATH_W + 1, _h - BORDER - PATH_W - 1)
	var ex = _h / 2 + _rng.randi_range(-_h / 6, _h / 6)
	ex = clampi(ex, BORDER + PATH_W + 1, _h - BORDER - PATH_W - 1)
	var segs = _rng.randi_range(4, 6)
	var seg_w = _w / (segs + 1)
	var pts: Array[Vector2i] = []
	pts.append(Vector2i(0, ey))
	var cy = ey
	var dy = 1
	for i in range(segs):
		var tx = seg_w * (i + 1) + _rng.randi_range(-seg_w / 3, seg_w / 3)
		tx = clampi(tx, BORDER + PATH_W + 1, _w - BORDER - PATH_W - 1)
		var ry = _h * _rng.randf_range(0.2, 0.35)
		var ty = cy + dy * ry
		ty = clampi(ty, BORDER + PATH_W + 1, _h - BORDER - PATH_W - 1)
		_carve_h(pts[-1].x, tx, cy)
		_carve_v(cy, ty, tx)
		cy = ty
		dy *= -1
		pts.append(Vector2i(tx, ty))
	_carve_h(pts[-1].x, _w - 1, cy)
	_carve_v(cy, ex, _w - 1)
	pts.append(Vector2i(_w - 1, ex))
	return pts

func _gen_random_walk() -> Array[Vector2i]:
	var cx = _rng.randi_range(BORDER, _w - BORDER - 1)
	var cy = _rng.randi_range(BORDER, _h - BORDER - 1)
	var pts: Array[Vector2i] = [Vector2i(cx, cy)]
	var steps = _rng.randi_range(_h * 2, _h * 3)
	var dirs = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for _i in range(steps):
		var d = dirs[_rng.randi_range(0, 3)]
		var nx = cx + d.x
		var ny = cy + d.y
		if not _inb(Vector2i(nx, ny)):
			continue
		if _gv(Vector2i(nx, ny)) == SRC_PATH:
			continue
		cx = nx
		cy = ny
		_sv(Vector2i(cx, cy), SRC_PATH)
		for wx in range(-PATH_W, PATH_W + 1):
			for wy in range(-PATH_W, PATH_W + 1):
				var n = Vector2i(cx + wx, cy + wy)
				if _inb(n):
					_sv(n, SRC_PATH)
		if _i % 20 == 0:
			pts.append(Vector2i(cx, cy))
	if pts.size() < 3:
		return _gen_serpentine()
	return pts

func _add_obstacles():
	var count = _rng.randi_range(5, 15)
	for _i in range(count):
		var x = _rng.randi_range(BORDER, _w - BORDER - 1)
		var y = _rng.randi_range(BORDER, _h - BORDER - 1)
		var c = Vector2i(x, y)
		if _gv(c) != SRC_GRASS:
			continue
		var blocked = false
		for ox in range(-(MIN_GAP + 1), MIN_GAP + 2):
			for oy in range(-(MIN_GAP + 1), MIN_GAP + 2):
				var n = Vector2i(x + ox, y + oy)
				if _inb(n) and (_gv(n) == SRC_PATH or _gv(n) == SRC_WALL):
					blocked = true
					break
			if blocked:
				break
		if not blocked:
			_sv(c, SRC_WALL)
			for ox in range(-1, 2):
				for oy in range(-1, 2):
					var n = Vector2i(x + ox, y + oy)
					if _inb(n) and _gv(n) == SRC_GRASS:
						_sv(n, SRC_WALL)

func _generate_slots(pts: Array[Vector2i], md: MapData):
	var n = md.slot_count
	var spacing = maxi(1, pts.size() / (n + 1))
	var names: Array[String] = []
	var positions: Array[Vector2] = []
	var diffs: Array[float] = []
	var taken: Array[Vector2i] = []
	for i in range(n):
		var idx = spacing * (i + 1)
		if idx >= pts.size():
			break
		var pp = pts[idx]
		var dir = Vector2i.ZERO
		if idx > 0 and idx < pts.size() - 1:
			dir = pts[idx + 1] - pts[idx - 1]
		else:
			dir = Vector2i.RIGHT
		var perp = Vector2(-dir.y, dir.x)
		if perp == Vector2.ZERO:
			perp = Vector2(0, 1)
		perp = perp.normalized() * 3.0
		var sp = Vector2i.ZERO
		for side in [1, -1]:
			var cand = pp + Vector2i(perp * side)
			if _inb(cand) and _gv(cand) == SRC_GRASS:
				var occ = false
				for t in taken:
					if t.distance_squared_to(cand) < 36:
						occ = true
						break
				if not occ:
					sp = cand
					break
		if sp == Vector2i.ZERO:
			continue
		taken.append(sp)
		var wp = _tilemap.map_to_local(sp)
		names.append("Slot%d" % (positions.size() + 1))
		positions.append(wp)
		var t = float(positions.size()) / n
		diffs.append(lerpf(1.0, 1.5, t))
	md.slot_names = names
	md.slot_positions = positions
	md.slot_difficulties = diffs