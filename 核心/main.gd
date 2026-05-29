extends Node2D

@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var start_btn: Button = $UI/HUD/StartWaveBtn
@onready var settings_btn: Button = $UI/HUD/SettingsBtn
@onready var settings_panel: Control = $UI/SettingsPanel
@onready var game_over_bg: ColorRect = $UI/GameOverBG
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var tower_slots: Node2D = $TowerSlots
@onready var wave_config_label: Label = $UI/WaveConfigLabel
@onready var tower_ring: Control = $UI/TowerActionRing

var tower_scene = preload("res://scenes/ArrowTower.tscn")

# 预计算点击半径平方，避免每帧 sqrt
const _CLICK_RADIUS_SQ: float = 20.0 * 20.0

func _ready() -> void:
	GameManager.reset()
	start_btn.pressed.connect(_on_start_wave)
	settings_btn.pressed.connect(_on_settings)
	GameManager.gold_changed.connect(_update_gold)
	GameManager.lives_changed.connect(_update_lives)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_done.connect(_on_wave_done)
	GameManager.game_over.connect(_on_game_over)
	_update_gold(100)
	_update_lives(20)
	_update_wave(0)
	AudioManager.play_music()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_spawn_test_enemy()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos := get_global_mouse_position()
		for slot in tower_slots.get_children():
			if slot is Marker2D:
				if slot.global_position.distance_squared_to(click_pos) < _CLICK_RADIUS_SQ:
					if slot.get_child_count() == 0:
						_place_tower(slot)
					else:
						tower_ring.show_for_tower(slot.get_child(0))
					get_viewport().set_input_as_handled()
					break


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tower_ring.visible:
			tower_ring.hide_ring()


func _place_tower(slot: Marker2D) -> void:
	if not GameManager.can_afford(50):
		return
	var tower = tower_scene.instantiate()
	tower.add_to_group("tower")
	slot.add_child(tower)
	tower.position = Vector2.ZERO
	GameManager.spend_gold(50)

func _spawn_test_enemy() -> void:
	print("=== 调试: 直接生成测试小怪 ===")
	var scene = preload("res://怪物/green_monster.tscn")
	var enemy = scene.instantiate()
	enemy.died.connect(_on_test_enemy_died)
	enemy.reached_end.connect(_on_test_enemy_reached_end)
	var path = get_tree().root.get_node("TowerDefense/EnemyPath")
	path.add_child(enemy)
	print("测试小怪已生成，路径: EnemyPath")

func _on_test_enemy_died(enemy):
	print("测试小怪被击杀，金币奖励: %d" % enemy.gold_reward)

func _on_test_enemy_reached_end():
	print("测试小怪到达终点")

func _on_settings() -> void:
	settings_panel.open()

func _on_start_wave() -> void:
	start_btn.disabled = true
	start_btn.text = "In Progress..."
	GameManager.start_wave()


func _update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


func _update_lives(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount


func _update_wave(wave: int) -> void:
	wave_label.text = "Wave: %d" % wave


func _on_wave_started(wave_number: int, count: int, spawn_interval: float) -> void:
	_update_wave(wave_number)
	wave_config_label.text = "Enemies: %d  |  Interval: %.1fs" % [count, spawn_interval]
	AudioManager.play_wave()


func _on_wave_done() -> void:
	start_btn.disabled = false
	start_btn.text = "Start Wave"
	wave_config_label.text = ""


func _on_game_over() -> void:
	game_over_bg.visible = true
	game_over_label.visible = true
	start_btn.visible = false
	AudioManager.play_gameover()
