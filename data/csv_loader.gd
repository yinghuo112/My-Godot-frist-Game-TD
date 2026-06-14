extends RefCounted
class_name CSVLoader

static func _parse(path: String) -> Array[Dictionary]:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSVLoader: 无法打开文件 ", path)
		return []
	var headers = file.get_csv_line()
	var rows: Array[Dictionary] = []
	while not file.eof_reached():
		var vals = file.get_csv_line()
		if vals.is_empty() or vals[0].is_empty():
			continue
		var row = {}
		for i in headers.size():
			row[headers[i]] = vals[i] if i < vals.size() else ""
		rows.append(row)
	return rows

static func load_enemies(path: String) -> Dictionary:
	var rows = _parse(path)
	var db = {}
	for r in rows:
		var e = EnemyType.new()
		e.display_name = r["display_name"]
		e.max_hp = float(r["max_hp"])
		e.speed = float(r["speed"])
		e.gold_reward = int(r["gold_reward"])
		e.lane_width = float(r["lane_width"])
		e.lane_change_speed = float(r["lane_change_speed"])
		e.scene = load(r["scene_path"])
		e.armor_physical = float(r["armor_physical"])
		e.armor_magic = float(r["armor_magic"])
		e.dodge_chance = float(r["dodge_chance"])
		db[r["id"]] = e
	return db

static func load_waves(path: String, enemies: Dictionary) -> Array:
	var rows = _parse(path)
	var waves = []
	for r in rows:
		var entry = preload("res://config/wave_entry.gd").new()
		entry.enemy_type = enemies.get(r["enemy_id"])
		entry.count = int(r["count"])
		entry.spawn_interval = float(r["spawn_interval"])
		entry.route = int(r["route"]) if r.has("route") else 1
		waves.append(entry)
	return waves
