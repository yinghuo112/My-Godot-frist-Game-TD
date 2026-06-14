extends Node

# --- 信号 ---
signal wave_started(wave_number, count, spawn_interval)  # 波次开始
signal wave_done                                         # 波次结束
signal enemy_killed(gold_reward)                         # 敌人被击杀
signal game_over                                         # 游戏结束
signal gold_changed(amount)                              # 金币变化
signal lives_changed(amount)                             # 生命值变化

# --- 游戏状态 ---
var gold: int = 1000
var lives: int = 20
var wave: int = 0
var enemies_to_spawn: int = 0
var enemies_on_field: int = 0
var is_wave_active: bool = false

var current_route: int = 1

var total_waves: int = 0
var timer: Timer
var _config: Array
var _current_entry
var _enemies_db: Dictionary = {}

# 初始化生成计时器和波次配置
func _ready():
	timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.timeout.connect(_spawn_enemy)
	add_child(timer)

	_config = _load_config()

# 重置所有游戏状态到初始值
func reset():
	gold = 1000
	lives = 20
	wave = 0
	enemies_to_spawn = 0
	enemies_on_field = 0
	is_wave_active = false
	if timer:
		timer.stop()

# --- 开始一波 ---
# 开始新一波敌人：读取配置，启动生成计时器
func start_wave():
	if is_wave_active:
		return

	wave += 1
	is_wave_active = true

	_current_entry = _get_wave_entry(wave)
	enemies_to_spawn = _current_entry.count
	enemies_on_field = 0
	timer.wait_time = _current_entry.spawn_interval
	timer.one_shot = false
	timer.start()

	print("第 %d 波开始: 敌人=%d, 间隔=%.1fs" % [wave, _current_entry.count, _current_entry.spawn_interval])
	wave_started.emit(wave, _current_entry.count, _current_entry.spawn_interval)

# --- 加载波次配置 ---
# 从 CSV 加载波次配置，失败时用默认配置
func _load_config() -> Array:
	_enemies_db = CSVLoader.load_enemies("res://data/enemies.csv")
	var waves = CSVLoader.load_waves("res://data/waves.csv", _enemies_db)
	if waves.is_empty():
		push_warning("CSV 波次为空，使用默认配置")
		var entry = preload("res://config/wave_entry.gd").new()
		entry.enemy_type = _enemies_db.get("goblin", null)
		entry.count = 12
		entry.spawn_interval = 0.5
		waves = [entry]
	total_waves = waves.size()
	print("波次配置加载成功: %d 个波次" % total_waves)
	return waves

# 根据波次号获取配置条目，超出则复用最后一波
func _get_wave_entry(wave_number: int):
	var idx = wave_number - 1
	if idx >= 0 and idx < _config.size():
		return _config[idx]
	return _config[-1] if _config.size() > 0 else _fallback_entry()

# 创建默认波次配置条目作为后备
func _fallback_entry():
	var entry = preload("res://config/wave_entry.gd").new()
	entry.enemy_type = _enemies_db.get("goblin", null)
	entry.count = 12
	entry.spawn_interval = 0.5
	return entry

# --- 批量生成怪物（每 tick 生成最多 3 只） ---
# 每 tick 批量生成最多 3 只敌人，分散在路径上
func _spawn_enemy():
	if enemies_to_spawn <= 0:
		timer.stop()
		return

	var batch = mini(3, enemies_to_spawn)
	for i in range(batch):
		# 优先使用 EnemyType 数据驱动，否则回退旧方式
		var enemy
		if _current_entry.enemy_type:
			enemy = _current_entry.enemy_type.scene.instantiate()
			enemy.init(_current_entry.enemy_type)
		else:
			enemy = _current_entry.enemy_scene.instantiate()
		enemy.died.connect(_on_enemy_died)
		enemy.reached_end.connect(_on_enemy_reached_end)
		var mm = get_tree().get_first_node_in_group("map_manager")
		var route = current_route
		if route == 0:
			route = 1 + (i % 2)
		var path = mm.get_enemy_path(route) if mm else get_tree().root.get_node("TowerDefense/EnemyPath")
		path.add_child(enemy)
		# 沿路径分散位置，避免全部堆叠在起点
		enemy.progress = i * 60 + randf_range(0, 30)
		# 垂直路径方向随机偏移，模拟区域散布
		enemy.h_offset = randf_range(-15, 15)
		# 速度随机化，让同一批怪物自然拉开距离并触发超车
		enemy.speed += randf_range(-40, 40)

	enemies_to_spawn -= batch
	enemies_on_field += batch

# --- 敌人死亡 / 到达终点 ---
# 敌人死亡：增加金币，检查波次是否结束
func _on_enemy_died(enemy):
	var reward = enemy.gold_reward
	gold += reward
	AudioManager.play("coin")
	gold_changed.emit(gold)
	enemy_killed.emit(reward)
	enemies_on_field -= 1
	_check_wave_done()

# 敌人到达终点：扣减生命值，检查是否游戏结束
func _on_enemy_reached_end():
	lives -= 1
	lives_changed.emit(lives)
	enemies_on_field -= 1
	if lives <= 0:
		game_over.emit()
		is_wave_active = false
		timer.stop()
	else:
		_check_wave_done()

# 检查当前波次是否全部敌人已生成且已消灭
func _check_wave_done():
	if enemies_to_spawn <= 0 and enemies_on_field <= 0:
		is_wave_active = false
		wave_done.emit()

# --- 金币操作 ---
# 增加金币并发射信号
func add_gold(amount):
	gold += amount
	gold_changed.emit(gold)

# 检查是否足以支付指定花费
func can_afford(cost: int) -> bool:
	return gold >= cost

# 扣除金币，返回是否成功
func spend_gold(cost: int) -> bool:
	if gold >= cost:
		gold -= cost
		gold_changed.emit(gold)
		return true
	return false
