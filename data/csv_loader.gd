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
		e.max_hp = float(r["max_hp"]) if not r["max_hp"].is_empty() else 1.0
		e.speed = float(r["speed"])
		e.gold_reward = int(r["gold_reward"])
		e.lane_width = float(r["lane_width"])
		e.lane_change_speed = float(r["lane_change_speed"])
		var scene_path = r["scene_path"]
		e.scene = load(scene_path)
		if not e.scene:
			push_warning("CSVLoader: 场景不存在 ", scene_path, " 使用默认")
		e.armor_physical = float(r["armor_physical"])
		e.armor_magic = float(r["armor_magic"])
		e.dodge_chance = float(r["dodge_chance"])
		db[r["id"]] = e
	return db

static func save_enemies(path: String, test_db: Dictionary) -> void:
	var rows = _parse(path)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("CSVLoader: 无法写入文件 ", path)
		return
	var headers = ["id","display_name","max_hp","speed","gold_reward","lane_width","lane_change_speed","scene_path","armor_physical","armor_magic","dodge_chance"]
	file.store_csv_line(headers)
	for r in rows:
		var id = r["id"]
		if id in test_db:
			var e = test_db[id]
			file.store_csv_line(PackedStringArray([
				id, e.display_name, str(e.max_hp), str(e.speed), str(e.gold_reward),
				str(e.lane_width), str(e.lane_change_speed), r["scene_path"],
				str(e.armor_physical), str(e.armor_magic), str(e.dodge_chance)
			]))
		else:
			file.store_csv_line(PackedStringArray([
				r["id"], r["display_name"], r["max_hp"], r["speed"], r["gold_reward"],
				r["lane_width"], r["lane_change_speed"], r["scene_path"],
				r["armor_physical"], r["armor_magic"], r["dodge_chance"]
			]))
	file.close()

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
