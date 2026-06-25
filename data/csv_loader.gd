extends RefCounted
class_name CSVLoader

static func _parse(path: String, skip_lines: int = 0) -> Array[Dictionary]:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSVLoader: 无法打开文件 ", path)
		return []
	var headers = file.get_csv_line()
	for _i in skip_lines:
		file.get_csv_line()
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

# ===== 🗼 塔数据 CSV 管理 =====

# CSV 列序: id,chinese_type,damage,fire_rate,range_radius,cost,
#           attack_type,crit_chance,crit_mult,hit_chance,
#           skill_name,skill_categories,战力,
#           scene_path,bullet_scene_path,display_name,description,
#           skill_book_path,chain_jumps,chain_falloff,chain_range,name_prefixes
# 行 1 = 英文头, 行 2 = 中文头（_parse 跳过）

const POWER_D_SQ: float = 32.2 * 32.2   # d² ≈ 1036.84
const POWER_LEN: float = 508.0           # 标准波总长度

static func _calc_power(damage: float, fire_rate: float, range_radius: float) -> float:
	if fire_rate <= 0.0:
		return 0.0
	var dps = damage / fire_rate
	var chord = 2.0 * sqrt(max(range_radius * range_radius - POWER_D_SQ, 0.0))
	return dps * (chord + POWER_LEN)

# 📥 从 CSV 加载所有塔类型 → {id: TowerType}
static func load_towers(path: String) -> Dictionary:
	var rows = _parse(path, 1)
	var db = {}
	for r in rows:
		var t = TowerType.new()
		t.chinese_type = r["chinese_type"]
		t.damage = float(r["damage"]) if not r["damage"].is_empty() else 5.0
		t.fire_rate = float(r["fire_rate"]) if not r["fire_rate"].is_empty() else 1.0
		t.range_radius = float(r["range_radius"]) if not r["range_radius"].is_empty() else 120.0
		t.cost = int(r["cost"]) if not r["cost"].is_empty() else 50
		t.attack_type = int(r["attack_type"]) if not r["attack_type"].is_empty() else 0
		t.crit_chance = float(r["crit_chance"]) if not r["crit_chance"].is_empty() else 0.1
		t.crit_mult = float(r["crit_mult"]) if not r["crit_mult"].is_empty() else 2.0
		t.hit_chance = float(r["hit_chance"]) if not r["hit_chance"].is_empty() else 0.95
		t.skill_name = r.get("skill_name", "")
		t.power = _calc_power(t.damage, t.fire_rate, t.range_radius)
		# 后段字段
		t.display_name = r.get("display_name", t.chinese_type)
		t.description = r.get("description", "")
		t.chain_jumps = int(r["chain_jumps"]) if not r.get("chain_jumps", "").is_empty() else 0
		t.chain_falloff = float(r["chain_falloff"]) if not r.get("chain_falloff", "").is_empty() else 1.0
		t.chain_range = float(r["chain_range"]) if not r.get("chain_range", "").is_empty() else 0.0
		# 📦 加载 PackedScene 资源
		var sp = r.get("scene_path", "")
		t.scene = load(sp) if not sp.is_empty() and sp != "空" else null
		if not t.scene:
			push_warning("⚠️ CSVLoader.load_towers: [%s] scene 不存在 → %s" % [r["id"], sp])
		var bp = r.get("bullet_scene_path", "")
		t.bullet_scene = load(bp) if not bp.is_empty() and bp != "空" else null
		var sbp = r.get("skill_book_path", "")
		t.skill_book = load(sbp) if not sbp.is_empty() and sbp != "空" else null
		# 🏷️ 解析管道分隔的 name_prefixes → Array[String]
		var np = r.get("name_prefixes", "")
		t.name_prefixes.clear()
		if not np.is_empty() and np != "空":
			for s in np.split("|"):
				t.name_prefixes.append(s)
		# 🏷️ 解析 skill_categories
		var sc = r.get("skill_categories", "")
		t.skill_categories.clear()
		if not sc.is_empty() and sc != "空":
			for s in sc.split("|"):
				t.skill_categories.append(s)
		db[r["id"]] = t
	return db

# 📤 保存塔数据回 CSV（只覆写指定的塔行）
static func save_towers(path: String, modified_db: Dictionary) -> void:
	var rows = _parse(path, 1)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("❌ CSVLoader.save_towers: 无法写入 ", path)
		return
	var headers_en = [
		"id", "chinese_type", "damage", "fire_rate", "range_radius",
		"cost", "attack_type", "crit_chance", "crit_mult", "hit_chance",
		"skill_name", "skill_categories", "战力",
		"scene_path", "bullet_scene_path", "display_name", "description",
		"skill_book_path", "chain_jumps", "chain_falloff", "chain_range",
		"name_prefixes"
	]
	var headers_cn = [
		"ID", "中文类型", "攻击力", "射速", "射程", "价格",
		"攻击类型", "暴击率", "暴击倍率", "命中率", "技能名",
		"技能类别", "战力", "场景路径", "子弹场景", "显示名称",
		"描述", "技能书路径", "链跳数", "链衰减", "链范围", "名称前缀"
	]
	file.store_csv_line(PackedStringArray(headers_en))
	file.store_csv_line(PackedStringArray(headers_cn))
	for r in rows:
		var rid = r["id"]
		if rid in modified_db:
			var t: TowerType = modified_db[rid]
			var scene_path = r.get("scene_path", "")
			if t.scene:
				scene_path = t.scene.resource_path
			var bullet_path = r.get("bullet_scene_path", "")
			if t.bullet_scene:
				bullet_path = t.bullet_scene.resource_path
			var skill_path = r.get("skill_book_path", "")
			if t.skill_book:
				skill_path = t.skill_book.resource_path
			t.power = _calc_power(t.damage, t.fire_rate, t.range_radius)
			file.store_csv_line(PackedStringArray([
				rid, t.chinese_type,
				str(t.damage), str(t.fire_rate), str(t.range_radius), str(t.cost),
				str(t.attack_type), str(t.crit_chance), str(t.crit_mult), str(t.hit_chance),
				t.skill_name,
				"|".join(t.skill_categories) if t.skill_categories.size() > 0 else "",
				str(t.power),
				scene_path, bullet_path, t.display_name, t.description,
				skill_path,
				str(t.chain_jumps), str(t.chain_falloff), str(t.chain_range),
				"|".join(t.name_prefixes) if t.name_prefixes.size() > 0 else ""
			]))
		else:
			var vals = PackedStringArray()
			for h in headers_en:
				vals.append(r.get(h, ""))
			file.store_csv_line(vals)
	file.close()
