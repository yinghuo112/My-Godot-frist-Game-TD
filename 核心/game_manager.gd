extends Node

signal wave_started(wave_number)
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

var enemy_scene = preload("res://怪物/green_monster.tscn")
var enemy_path: Path2D
var timer: Timer

func _ready():
	timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.timeout.connect(_spawn_enemy)
	add_child(timer)

func start_wave():
	if is_wave_active:
		return

	wave += 1
	is_wave_active = true
	wave_started.emit(wave)

	enemies_to_spawn = 8 + wave * 4
	enemies_on_field = 0
	timer.wait_time = maxf(0.2, 0.8 - wave * 0.05)
	enemy_path = get_tree().root.get_node("TowerDefense/EnemyPath")
	timer.one_shot = false
	timer.start()

func _spawn_enemy():
	if enemies_to_spawn <= 0:
		timer.stop()
		return
	var enemy = enemy_scene.instantiate()
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
