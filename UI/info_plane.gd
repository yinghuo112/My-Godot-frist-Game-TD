extends PanelContainer

const PANEL_WIDTH: float = 300.0

var _target_tower: Node2D = null
var _tween: Tween = null
var _is_open: bool = false

signal closed()
signal skill_book_requested(tower)

@onready var close_btn: Button = %CloseBtn
@onready var icon_rect: TextureRect = %IconTextureRect
@onready var name_label: Label = %TowerNameLabel
@onready var level_label: Label = %LevelLabel
@onready var attr_grid: GridContainer = %AttrGrid
@onready var desc_label: RichTextLabel = %DescLabel
@onready var upgrade_btn: Button = %UpgradeBtn
@onready var sell_btn: Button = %SellBtn
@onready var skill_btn: Button = %SkillBtn

func _ready() -> void:
	close_btn.pressed.connect(_close)
	upgrade_btn.pressed.connect(_on_upgrade)
	sell_btn.pressed.connect(_on_sell)
	if skill_btn:
		skill_btn.pressed.connect(_on_skill_click)

func show_for_tower(tower: Node2D) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_target_tower = tower
	_populate(tower)
	visible = true
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "offset_left", 0.0, 0.3)
	_is_open = true

func _close() -> void:
	if not _is_open:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "offset_left", PANEL_WIDTH + 20.0, 0.25)
	_tween.tween_callback(func():
		visible = false
		_is_open = false
		closed.emit()
	)

func close() -> void:
	_close()

func hide_instantly() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	offset_left = PANEL_WIDTH + 20.0
	visible = false
	_is_open = false

func _populate(tower: Node2D) -> void:
	if not tower.has_method("init") or not tower.has_method("get_current_damage"):
		return

	var tt = tower.tower_type if "tower_type" in tower else null
	if not tt:
		return

	name_label.text = tt.display_name
	level_label.text = "Lv." + str(tower.level)

	var dmg = tower.get_current_damage()
	var fr = tower.get_current_fire_rate()
	var rng = tower.get_current_range()
	var attack_name = "物理" if tt.attack_type == 0 else "魔法"

	clear_stats()
	set_stat("攻击力:", "%.1f (%s)" % [dmg, attack_name])
	set_stat("攻速:", "%.2f/s" % [1.0 / fr])
	set_stat("射程:", "%.0f" % [rng])
	set_stat("暴击率:", "%d%%" % [tt.crit_chance * 100])
	set_stat("暴击倍率:", "x%.1f" % [tt.crit_multiplier])
	set_stat("命中率:", "%d%%" % [tt.hit_chance * 100])

	if tt.description and tt.description != "":
		desc_label.text = tt.description
		desc_label.show()
	else:
		desc_label.hide()

	upgrade_btn.disabled = not tower.can_upgrade() if tower.has_method("can_upgrade") else true
	sell_btn.disabled = false
	if skill_btn:
		skill_btn.visible = tt.get("skill_book") != null

func _on_skill_click() -> void:
	if is_instance_valid(_target_tower):
		skill_book_requested.emit(_target_tower)
		_close()

func _on_upgrade() -> void:
	if not is_instance_valid(_target_tower) or not _target_tower.has_method("do_upgrade"):
		return
	if not _target_tower.do_upgrade():
		return
	_populate(_target_tower)

func _on_sell() -> void:
	if not is_instance_valid(_target_tower) or not _target_tower.has_method("get_sell_value"):
		return
	var value = _target_tower.get_sell_value()
	GameManager.add_gold(value)
	_target_tower.queue_free()
	_close()

func _input(event: InputEvent) -> void:
	if _is_open and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()

func set_stat(label: String, value: String) -> void:
	var key = Label.new()
	key.text = label
	var val = Label.new()
	val.text = value
	attr_grid.add_child(key)
	attr_grid.add_child(val)

func set_description(text: String) -> void:
	desc_label.text = text

func set_upgrade_callback(callable: Callable) -> void:
	upgrade_btn.pressed.connect(callable)

func set_sell_callback(callable: Callable) -> void:
	sell_btn.pressed.connect(callable)

func clear_stats() -> void:
	for c in attr_grid.get_children():
		c.queue_free()
