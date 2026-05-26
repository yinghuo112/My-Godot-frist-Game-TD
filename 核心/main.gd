extends Node2D

@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var start_btn: Button = $UI/HUD/StartWaveBtn
@onready var game_over_bg: ColorRect = $UI/GameOverBG
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var tower_slots: Node2D = $TowerSlots

var tower_scene = preload("res://scenes/ArrowTower.tscn")

# 预计算点击半径平方，避免每帧 sqrt
const _CLICK_RADIUS_SQ: float = 20.0 * 20.0

func _ready() -> void:
	start_btn.pressed.connect(_on_start_wave)
	GameManager.gold_changed.connect(_update_gold)
	GameManager.lives_changed.connect(_update_lives)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_done.connect(_on_wave_done)
	GameManager.game_over.connect(_on_game_over)
	_update_gold(100)
	_update_lives(20)
	_update_wave(0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos := get_global_mouse_position()
		for slot in tower_slots.get_children():
			if slot is Marker2D and slot.get_child_count() == 0:
				if slot.global_position.distance_squared_to(click_pos) < _CLICK_RADIUS_SQ:
					_place_tower(slot)
					break  # 找到就不再检查其他 slot


func _place_tower(slot: Marker2D) -> void:
	if not GameManager.can_afford(50):
		return
	var tower = tower_scene.instantiate()
	tower.add_to_group("tower")
	slot.add_child(tower)
	tower.position = Vector2.ZERO
	GameManager.spend_gold(50)

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


func _on_wave_started(wave_number: int) -> void:
	_update_wave(wave_number)


func _on_wave_done() -> void:
	start_btn.disabled = false
	start_btn.text = "Start Wave"


func _on_game_over() -> void:
	game_over_bg.visible = true
	game_over_label.visible = true
	start_btn.visible = false
