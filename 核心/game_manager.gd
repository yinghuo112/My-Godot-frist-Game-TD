extends Node

# --- 信号 ---
signal wave_started(wave_number, count, spawn_interval)  # 波次开始
signal wave_done                                         # 波次结束
signal enemy_killed(gold_reward)                         # 敌人被击杀
signal game_over                                         # 游戏结束
signal gold_changed(amount)                              # 金币变化
signal lives_changed(amount)                             # 生命值变化

# --- 游戏状态 ---
var gold: int = 100
var lives: int = 20
var wave: int = 0
var enemies_to_spawn: int = 0       # 当前波次还未生成的敌人数
var enemies_on_field: int = 0       # 当前在场上的敌人数
var is_wave_active: bool = false    # 波次进行中锁定，防止重复点击

var enemy_path: Path2D              # 敌人路径节点
var timer: Timer                    # 生成定时器
var _config: WaveConfigData         # 波次配置数据
var _current_entry: WaveEntry       # 当前波次配置条目

func _ready():
	timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.timeout.connect(_spawn_enemy)
	add_child(timer)

	_config = _load_config()

# --- 开始一波 ---
func start_wave():
	if is_wave_active:
		return

	wave += 1
	is_wave_active = true

	_current_entry = _get_wave_entry(wave)
	enemies_to_spawn = _current_entry.count
	enemies_on_field = 0
	timer.wait_time = _current_entry.spawn_interval
	enemy_path = get_tree().root.get_node("TowerDefense/EnemyPath")
	timer.one_shot = false
	timer.start()

	print("第 %d 波开始: 敌人=%d, 间隔=%.1fs" % [wave, _current_entry.count, _current_entry.spawn_interval])
	wave_started.emit(wave, _current_entry.count, _current_entry.spawn_interval)

# --- 加载波次配置 ---
func _load_config() -> WaveConfigData:
	print("尝试加载波次配置: res://配置/wave_config.tres")
	if ResourceLoader.exists("res://配置/wave_config.tres"):
		var data: WaveConfigData = load("res://配置/wave_config.tres")
		if data and data.waves.size() > 0:
			print("波次配置加载成功: %d 个波次" % data.waves.size())
			return data
		print("配置文件存在但数据无效，使用默认配置")
	else:
		print("配置文件不存在，使用默认配置")
	var entry = WaveEntry.new()
	entry.enemy_scene = preload("res://怪物/green_monster.tscn")
	entry.count = 12
	entry.spawn_interval = 0.5
	var fallback = WaveConfigData.new()
	fallback.waves = [entry]
	print("使用默认配置: 敌人=12, 间隔=0.5s")
	return fallback

func _get_wave_entry(wave_number: int) -> WaveEntry:
	var idx = wave_number - 1
	if idx >= 0 and idx < _config.waves.size():
		return _config.waves[idx]
	# 超出配置则重复使用最后一波
	return _config.waves[-1] if _config.waves.size() > 0 else _fallback_entry()

func _fallback_entry() -> WaveEntry:
	var entry = WaveEntry.new()
	entry.enemy_scene = preload("res://怪物/green_monster.tscn")
	entry.count = 12
	entry.spawn_interval = 0.5
	return entry

# --- 批量生成怪物（每 tick 生成最多 3 只） ---
func _spawn_enemy():
	if enemies_to_spawn <= 0:
		timer.stop()
		return

	var batch = mini(3, enemies_to_spawn)
	for i in range(batch):
		var enemy = _current_entry.enemy_scene.instantiate()
		enemy.died.connect(_on_enemy_died)
		enemy.reached_end.connect(_on_enemy_reached_end)
		enemy_path.add_child(enemy)
		# 沿路径分散位置，避免全部堆叠在起点
		enemy.progress = i * 60 + randf_range(0, 30)
		# 垂直路径方向随机偏移，模拟区域散布
		enemy.h_offset = randf_range(-15, 15)
		# 速度随机化，让同一批怪物自然拉开距离并触发超车
		enemy.speed += randf_range(-40, 40)

	enemies_to_spawn -= batch
	enemies_on_field += batch

# --- 敌人死亡 / 到达终点 ---
func _on_enemy_died(enemy):
	var reward = enemy.gold_reward
	gold += reward
	gold_changed.emit(gold)
	enemy_killed.emit(reward)
	enemies_on_field -= 1
	_check_wave_done()

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

# --- 检查波次是否结束 ---
func _check_wave_done():
	if enemies_to_spawn <= 0 and enemies_on_field <= 0:
		is_wave_active = false
		wave_done.emit()

# --- 金币操作 ---
func add_gold(amount):
	gold += amount
	gold_changed.emit(gold)

func can_afford(cost: int) -> bool:
	return gold >= cost

func spend_gold(cost: int) -> bool:
	if gold >= cost:
		gold -= cost
		gold_changed.emit(gold)
		return true
	return false
