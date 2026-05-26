extends Node

signal wave_started(wave_number, count, spawn_interval)
signal wave_done
signal enemy_killed(gold_reward)
signal game_over
signal gold_changed(amount)
signal lives_changed(amount)

var gold: int = 100
var lives: int = 20
var wave: int = 0
var enemies_to_spawn: int = 0
var enemies_on_field: int = 0
var is_wave_active: bool = false

var enemy_path: Path2D
var timer: Timer
var _config: WaveConfigData
var _current_entry: WaveEntry

func _ready():
	timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.timeout.connect(_spawn_enemy)
	add_child(timer)

	_config = _load_config()

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
	return _config.waves[-1] if _config.waves.size() > 0 else _fallback_entry()

func _fallback_entry() -> WaveEntry:
	var entry = WaveEntry.new()
	entry.enemy_scene = preload("res://怪物/green_monster.tscn")
	entry.count = 12
	entry.spawn_interval = 0.5
	return entry

func _spawn_enemy():
	if enemies_to_spawn <= 0:
		timer.stop()
		return
	var enemy = _current_entry.enemy_scene.instantiate()
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy_path.add_child(enemy)
	enemies_to_spawn -= 1
	enemies_on_field += 1

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

func _check_wave_done():
	if enemies_to_spawn <= 0 and enemies_on_field <= 0:
		is_wave_active = false
		wave_done.emit()

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
