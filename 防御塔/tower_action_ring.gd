extends Control

# 环形菜单：点击塔后在周围弹出的操作按钮（升级 / 出售 / 信息）
# 所有弹窗信息统一使用 InfoPopupPanel 子节点

const RADIUS: float = 75.0
var floating_text_scene = preload("res://工具/FloatingText.tscn")

var target_tower: Node2D = null
var _confirm_action: Callable = Callable()
var _popup_mode: String = ""

@onready var btn_upgrade: Button = $BtnUpgrade
@onready var btn_sell: Button = $BtnSell
@onready var btn_info: Button = $BtnInfo
@onready var info_popup: PanelContainer = $InfoPopupPanel
@onready var popup_label: Label = $InfoPopupPanel/Margin/VBox/PopupLabel
@onready var confirm_btn: Button = $InfoPopupPanel/Margin/VBox/HBox/ConfirmBtn
@onready var cancel_btn: Button = $InfoPopupPanel/Margin/VBox/HBox/CancelBtn

# 连接按钮信号，初始隐藏
func _ready():
	btn_upgrade.pressed.connect(_on_upgrade_click)
	btn_sell.pressed.connect(_on_sell_click)
	btn_info.pressed.connect(_on_info_click)
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	hide()

# 在目标塔周围显示环形菜单，更新按钮状态
func show_for_tower(tower: Node2D):
	if not is_instance_valid(tower):
		return
	target_tower = tower

	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var viewport = get_viewport()
	var center = (tower.global_position - camera.global_position) * camera.zoom
	center += viewport.get_visible_rect().size / 2

	var half = btn_upgrade.size / 2
	btn_upgrade.position = center + Vector2(0, -RADIUS) - half
	btn_sell.position = center + Vector2(-RADIUS * 0.866, RADIUS * 0.5) - half
	btn_info.position = center + Vector2(RADIUS * 0.866, RADIUS * 0.5) - half

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

	_popup_mode = ""
	info_popup.hide()
	visible = true

# 隐藏环形菜单并清空状态
func hide_ring():
	visible = false
	_popup_mode = ""
	info_popup.hide()
	target_tower = null

# ==================== 按钮点击回调 ====================

# 点击升级按钮：弹窗显示升级前后属性对比
func _on_upgrade_click():
	if not is_instance_valid(target_tower) or not target_tower.has_method("can_upgrade") or not target_tower.can_upgrade():
		return
	if info_popup.visible and _popup_mode == "upgrade":
		info_popup.hide()
		_popup_mode = ""
		return
	var pos = btn_upgrade.position + Vector2(btn_upgrade.size.x + 8, -10)
	var lv = target_tower.level
	var dmg = target_tower.get_current_damage()
	var fr = target_tower.get_current_fire_rate()
	var rng = target_tower.get_current_range()
	var next_dmg = target_tower.damage * pow(1.5, lv)
	var next_fr = target_tower.fire_rate * pow(0.85, lv)
	var next_rng = target_tower.range_radius * pow(1.1, lv)
	var cost = target_tower.get_upgrade_cost()
	popup_label.text = "升级到 Lv.%d\n伤害: %.1f → %.1f\n射速: %.2fs → %.2fs\n射程: %.0f → %.0f\n花费 %d 金" % [lv+1, dmg, next_dmg, fr, next_fr, rng, next_rng, cost]
	_confirm_action = Callable(self, "_do_upgrade")
	confirm_btn.show()
	cancel_btn.show()
	info_popup.position = pos
	_popup_mode = "upgrade"
	info_popup.show()

# 点击出售按钮：弹窗确认出售金额
func _on_sell_click():
	if not is_instance_valid(target_tower):
		return
	if info_popup.visible and _popup_mode == "sell":
		info_popup.hide()
		_popup_mode = ""
		return
	var pos = btn_sell.position + Vector2(btn_sell.size.x + 8, -10)
	var value = target_tower.get_sell_value()
	popup_label.text = "出售塔获得 " + str(value) + " 金"
	_confirm_action = Callable(self, "_do_sell")
	confirm_btn.show()
	cancel_btn.show()
	info_popup.position = pos
	_popup_mode = "sell"
	info_popup.show()

# 点击信息按钮：显示当前塔的属性
func _on_info_click():
	if not is_instance_valid(target_tower):
		return
	if info_popup.visible and _popup_mode == "info":
		info_popup.hide()
		_popup_mode = ""
		return
	var pos = btn_info.position + Vector2(btn_info.size.x + 8, -10)
	var lv = target_tower.level
	var dmg = target_tower.get_current_damage()
	var fr = target_tower.get_current_fire_rate()
	var rng = target_tower.get_current_range()
	popup_label.text = "Lv." + str(lv) + "\n伤害: %.1f\n射速: %.2fs\n射程: %.0f" % [dmg, fr, rng]
	confirm_btn.hide()
	cancel_btn.hide()
	info_popup.position = pos
	_popup_mode = "info"
	info_popup.show()

# ==================== 确认 / 取消 ====================

# 确认操作：执行升级或出售
func _on_confirm():
	if _confirm_action.is_valid():
		_confirm_action.call()
	info_popup.hide()
	_popup_mode = ""
	if is_instance_valid(target_tower):
		show_for_tower(target_tower)

# 取消操作：关闭弹窗
func _on_cancel():
	info_popup.hide()
	_popup_mode = ""

# 执行升级：调用塔的升级接口，失败时显示金币不足
func _do_upgrade():
	if not is_instance_valid(target_tower) or not target_tower.has_method("do_upgrade"):
		return
	if not target_tower.do_upgrade():
		_show_floating_text("金币不足。。")
		return
	if is_instance_valid(target_tower):
		show_for_tower(target_tower)

# 在塔位置显示浮动提示文字
func _show_floating_text(msg: String):
	if not is_instance_valid(target_tower):
		return
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var world_to_screen = (target_tower.global_position - camera.global_position) * camera.zoom
	var screen_pos = viewport_size / 2 + world_to_screen

	var ft = floating_text_scene.instantiate()
	ft.text = msg
	ft.position = screen_pos - Vector2(100, 60)
	add_child(ft)

# 执行出售：回收金币，删除塔
func _do_sell():
	if not is_instance_valid(target_tower) or not target_tower.has_method("get_sell_value"):
		return
	var value = target_tower.get_sell_value()
	GameManager.add_gold(value)
	target_tower.queue_free()
	hide_ring()
