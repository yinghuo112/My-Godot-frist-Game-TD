extends Control

# 在 TowerActionRing.gd 顶部定义一个偏移常量
const UI_OFFSET = Vector2(0, -30)

# --- 信号与引用 ---
signal show_info_requested(tower)

var floating_text_scene = preload("res://工具/FloatingText.tscn")
var target_tower: Node2D = null
var _confirm_action: Callable = Callable()

@onready var btn_upgrade: Button = $BtnUpgrade
@onready var btn_sell: Button = $BtnSell
@onready var btn_info: Button = $BtnInfo
@onready var info_popup: PanelContainer = $InfoPopupPanel
@onready var popup_label: Label = $InfoPopupPanel/Margin/VBox/PopupLabel
@onready var confirm_btn: Button = $InfoPopupPanel/Margin/VBox/HBox/ConfirmBtn
@onready var cancel_btn: Button = $InfoPopupPanel/Margin/VBox/HBox/CancelBtn

# --- 初始化 ---
func _ready() -> void:
	# 确保信号连接，这里使用 callable 方式避免编辑器面板连接产生的隐患
	btn_upgrade.pressed.connect(_on_upgrade_click)
	btn_sell.pressed.connect(_on_sell_click)
	btn_info.pressed.connect(_on_info_click)
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	
	if not Engine.is_editor_hint():
		hide()

# --- 核心逻辑 ---
func show_for_tower(tower: Node2D) -> void:
	if not is_instance_valid(tower):
		return
	
	target_tower = tower
	visible = true
	
	# 规范化的屏幕坐标定位：使用 get_global_transform_with_canvas
	# 这样 UI 会准确出现在塔的中心点，且不受相机缩放和位移影响
	var screen_pos = tower.get_global_transform_with_canvas().origin
	position = screen_pos - (size / 2) + UI_OFFSET
	
	_update_ui_state(tower)
	info_popup.hide()

func _update_ui_state(tower: Node2D) -> void:
	var can_up = tower.has_method("can_upgrade") and tower.can_upgrade()
	btn_upgrade.disabled = !can_up
	btn_upgrade.text = "升级" if can_up else "满级"

func hide_ring() -> void:
	visible = false
	info_popup.hide()
	target_tower = null

# --- 按钮信号处理 (确保这些函数在类内，没有被嵌套) ---
func _on_upgrade_click() -> void:
	if not is_instance_valid(target_tower): return
	popup_label.text = "确认升级至 Lv.%d?" % (target_tower.level + 1)
	_confirm_action = _do_upgrade
	info_popup.show()

func _on_sell_click() -> void:
	if not is_instance_valid(target_tower): return
	popup_label.text = "确认出售？"
	_confirm_action = _do_sell
	info_popup.show()

func _on_info_click() -> void:
	if not is_instance_valid(target_tower): return
	show_info_requested.emit(target_tower)

# --- 确认操作 ---
func _on_confirm() -> void:
	if _confirm_action.is_valid():
		_confirm_action.call()
	info_popup.hide()

func _on_cancel() -> void:
	info_popup.hide()

func _do_upgrade() -> void:
	if target_tower.has_method("do_upgrade") and target_tower.do_upgrade():
		_update_ui_state(target_tower)
	else:
		_show_floating_text("金币不足")

func _do_sell() -> void:
	GameManager.add_gold(target_tower.get_sell_value())
	var mm = get_tree().get_first_node_in_group("map_manager")
	if mm and mm.has_method("free_slot_at"):
		mm.free_slot_at(target_tower.global_position)
	target_tower.queue_free()
	hide_ring()

func _show_floating_text(msg: String) -> void:
	var ft = floating_text_scene.instantiate()
	ft.text = msg
	ft.position = target_tower.get_global_transform_with_canvas().origin
	get_parent().add_child(ft)
