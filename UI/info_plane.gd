# ===== 塔信息面板 =====
# 继承 ui_panel_base，展示选中塔的属性/技能/升级/出售
# 入口：show_for_tower(tower) → 调用 show_panel() 滑入

extends PanelBase

# 额外信号：打开技能书
signal skill_book_requested(tower)

@onready var icon_rect: TextureRect = %IconTextureRect
@onready var name_label: Label = %TowerNameLabel
@onready var level_label: Label = %LevelLabel
@onready var attr_grid: GridContainer = %AttrGrid
@onready var desc_label: RichTextLabel = %DescLabel
@onready var upgrade_btn: Button = %UpgradeBtn
@onready var sell_btn: Button = %SellBtn
@onready var skill_btn: Button = %SkillBtn

func _ready() -> void:
	# 连接基类关闭按钮
	_connect_close_btn(%CloseBtn)
	# 连接业务按钮
	upgrade_btn.pressed.connect(_on_upgrade)
	sell_btn.pressed.connect(_on_sell)
	if skill_btn:
		skill_btn.pressed.connect(_on_skill_click)
	hide_instantly()

# 打开面板，展示指定塔的信息
func show_for_tower(tower: Node2D) -> void:
	_target_tower = tower
	_populate(tower)
	show_panel()

# 填充塔属性到面板（虚函数实现）
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


# ===== 业务逻辑 =====

# 点击技能按钮 → 打开技能书面板
func _on_skill_click() -> void:
	if is_instance_valid(_target_tower):
		skill_book_requested.emit(_target_tower)
		close()

# 升级塔
func _on_upgrade() -> void:
	if not is_instance_valid(_target_tower) or not _target_tower.has_method("do_upgrade"):
		return
	if not _target_tower.do_upgrade():
		return
	_populate(_target_tower)

# 出售塔
func _on_sell() -> void:
	if not is_instance_valid(_target_tower) or not _target_tower.has_method("get_sell_value"):
		return
	var value = _target_tower.get_sell_value()
	GameManager.add_gold(value)
	_target_tower.queue_free()
	close()

# 在属性网格中添加一行统计
func set_stat(label_text: String, value_text: String) -> void:
	var key = Label.new()
	key.text = label_text
	var val = Label.new()
	val.text = value_text
	attr_grid.add_child(key)
	attr_grid.add_child(val)

# 设置描述文本
func set_description(text: String) -> void:
	desc_label.text = text

# 设置升级回调
func set_upgrade_callback(callable: Callable) -> void:
	upgrade_btn.pressed.connect(callable)

# 设置出售回调
func set_sell_callback(callable: Callable) -> void:
	sell_btn.pressed.connect(callable)

# 清空属性网格
func clear_stats() -> void:
	for c in attr_grid.get_children():
		c.queue_free()
