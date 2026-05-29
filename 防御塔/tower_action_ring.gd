extends Control

# 环形菜单：点击塔后在周围弹出的操作按钮（升级 / 出售 / 信息）
# 按钮固定在塔的屏幕坐标附近，不遮挡游戏操作

# 按钮距离塔中心的像素半径
const RADIUS: float = 75.0

var target_tower: Node2D = null      # 当前环形正在操作的塔对象
var _confirm_action: Callable = Callable()  # 确认按钮绑定的回调函数

@onready var btn_upgrade: Button = $BtnUpgrade
@onready var btn_sell: Button = $BtnSell
@onready var btn_info: Button = $BtnInfo
@onready var confirm_popup: Panel = $ConfirmPopup         # 确认操作浮窗
@onready var confirm_label: Label = $ConfirmPopup/Margin/VBox/Label
@onready var confirm_btn: Button = $ConfirmPopup/Margin/VBox/HBox/ConfirmBtn
@onready var cancel_btn: Button = $ConfirmPopup/Margin/VBox/HBox/CancelBtn
@onready var info_popup: PanelContainer = $InfoPopupPanel
@onready var stats_label: Label = $InfoPopupPanel/Margin/StatsLabel

func _ready():
	btn_upgrade.pressed.connect(_on_upgrade_click)
	btn_sell.pressed.connect(_on_sell_click)
	btn_info.pressed.connect(_on_info_click)
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	confirm_popup.hide()
	info_popup.hide()
	hide()

# 打开环形菜单并定位到指定塔周围
func show_for_tower(tower: Node2D):
	if not is_instance_valid(tower):
		return
	target_tower = tower

	# 将塔的世界坐标转为屏幕坐标（用于 CanvasLayer 定位）
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var viewport = get_viewport()
	var center = (tower.global_position - camera.global_position) * camera.zoom
	center += viewport.get_visible_rect().size / 2

	# 三个按钮围绕塔呈半圆形分布（上、左下、右下）
	var half = btn_upgrade.size / 2
	btn_upgrade.position = center + Vector2(0, -RADIUS) - half
	btn_sell.position = center + Vector2(-RADIUS * 0.866, RADIUS * 0.5) - half
	btn_info.position = center + Vector2(RADIUS * 0.866, RADIUS * 0.5) - half

	# 根据塔是否可升级来切换按钮文字和禁用状态
	if tower.has_method("can_upgrade") and tower.can_upgrade():
		btn_upgrade.disabled = false
		btn_upgrade.text = "升级"
		if tower.has_method("get_upgrade_cost"):
			btn_upgrade.tooltip_text = "花费 " + str(tower.get_upgrade_cost()) + " 金"
	else:
		btn_upgrade.disabled = true
		btn_upgrade.text = "满级"

	if tower.has_method("get_sell_value"):
		btn_sell.tooltip_text = "回收 " + str(tower.get_sell_value()) + " 金"
	btn_sell.disabled = false

	confirm_popup.hide()
	info_popup.hide()
	visible = true

# 关闭环形菜单
func hide_ring():
	visible = false
	confirm_popup.hide()
	info_popup.hide()
	target_tower = null

# ==================== 按钮点击回调 ====================

# 升级按钮：显示当前属性 → 升级后属性的对比 + 花费
func _on_upgrade_click():
	if not is_instance_valid(target_tower) or not target_tower.has_method("can_upgrade") or not target_tower.can_upgrade():
		return
	var lv = target_tower.level
	var dmg = target_tower.get_current_damage()
	var fr = target_tower.get_current_fire_rate()
	var rng = target_tower.get_current_range()
	var next_dmg = target_tower.damage * pow(1.5, lv)
	var next_fr = target_tower.fire_rate * pow(0.85, lv)
	var next_rng = target_tower.range_radius * pow(1.1, lv)
	var cost = target_tower.get_upgrade_cost()
	confirm_label.text = "升级到 Lv.%d\n伤害: %.1f → %.1f\n射速: %.2fs → %.2fs\n射程: %.0f → %.0f\n花费 %d 金" % [lv+1, dmg, next_dmg, fr, next_fr, rng, next_rng, cost]
	_confirm_action = Callable(self, "_do_upgrade")
	_show_confirm_near(btn_upgrade)

# 出售按钮：显示回收价格并确认
func _on_sell_click():
	if not is_instance_valid(target_tower):
		return
	var value = target_tower.get_sell_value()
	confirm_label.text = "出售塔获得 " + str(value) + " 金"
	_confirm_action = Callable(self, "_do_sell")
	_show_confirm_near(btn_sell)

# 信息按钮：显示塔的当前属性（无需确认）
func _on_info_click():
	if not is_instance_valid(target_tower):
		return
	var lv = target_tower.level
	var dmg = target_tower.get_current_damage()
	var fr = target_tower.get_current_fire_rate()
	var rng = target_tower.get_current_range()
	stats_label.text = "Lv." + str(lv) + "\n伤害: %.1f\n射速: %.2fs\n射程: %.0f" % [dmg, fr, rng]
	_show_info_near(btn_info)


# 在按钮旁显示确认浮窗
func _show_confirm_near(btn: Button, show_btns: bool = true):
	confirm_popup.position = btn.position + Vector2(btn.size.x + 8, -10)
	confirm_btn.visible = show_btns
	cancel_btn.visible = show_btns
	confirm_popup.show()

# 在按钮旁显示信息浮窗
func _show_info_near(btn: Button):
	info_popup.position = btn.position + Vector2(btn.size.x + 8, -10)
	info_popup.show()

# ==================== 确认 / 取消 ====================

# 确认：执行回调后刷新环形
func _on_confirm():
	if _confirm_action.is_valid():
		_confirm_action.call()
	confirm_popup.hide()
	if is_instance_valid(target_tower):
		show_for_tower(target_tower)

# 取消：仅关闭确认浮窗
func _on_cancel():
	confirm_popup.hide()

# ==================== 实际操作 ====================

# 执行升级
func _do_upgrade():
	if not is_instance_valid(target_tower) or not target_tower.has_method("do_upgrade"):
		return
	target_tower.do_upgrade()

# 执行出售：加钱 → 删除塔 → 关闭环形
func _do_sell():
	if not is_instance_valid(target_tower) or not target_tower.has_method("get_sell_value"):
		return
	var value = target_tower.get_sell_value()
	GameManager.add_gold(value)
	target_tower.queue_free()
	hide_ring()
