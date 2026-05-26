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
var _enemy_path: Path2D
var _spawn_timer: Timer

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.name = "SpawnTimer"
	_spawn_timer.timeout.connect(_spawn_enemy)
	add_child(_spawn_timer)


func start_wave() -> void:
	wave += 1
	is_wave_active = true
	emit_signal("wave_started", wave)
	enemies_to_spawn = 8 + wave * 4
	enemies_on_field = 0
	_spawn_timer.wait_time = maxf(0.2, 0.8 - wave * 0.05)
	_spawn_timer.one_shot = false
	_spawn_timer.start()


func _spawn_enemy() -> void:
	if enemies_to_spawn <= 0:
		_spawn_timer.stop()
		return
	var enemy = enemy_scene.instantiate()
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	if not _enemy_path:
		_enemy_path = get_tree().root.get_node("TowerDefense/EnemyPath")
	_enemy_path.add_child(enemy)
	enemies_to_spawn -= 1
	enemies_on_field += 1


func _on_enemy_died(enemy: Node) -> void:
	gold += enemy.gold_reward
	enemies_on_field -= 1
	emit_signal("gold_changed", gold)
	emit_signal("enemy_killed", enemy.gold_reward)
	_check_wave_done()


func _on_enemy_reached_end() -> void:
	lives -= 1
	enemies_on_field -= 1
	emit_signal("lives_changed", lives)
	if lives <= 0:
		emit_signal("game_over")
		is_wave_active = false
		_spawn_timer.stop()
	else:
		_check_wave_done()


func _check_wave_done() -> void:
	if enemies_to_spawn <= 0 and enemies_on_field <= 0:
		is_wave_active = false
		emit_signal("wave_done")

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

func can_afford(cost: int) -> bool:
	return gold >= cost


func spend_gold(cost: int) -> bool:
	if gold >= cost:
		gold -= cost
		emit_signal("gold_changed", gold)
		return true
	return false
