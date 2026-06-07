# ========================================
# MobileUIAdapter.gd —— UI 自适应工具模块
# ========================================
# 提供静态方法，用于调整界面布局以适应手机屏幕
# 用法：MobileUIAdapter.resize_panel(panel, screen_ratio)
# ========================================

extends Node

# ===== 屏幕参考尺寸 =====
const DESIGN_WIDTH: float = 1280.0
const DESIGN_HEIGHT: float = 720.0

# ========================================
# 面板尺寸自适应
# ========================================

# 按屏幕宽度百分比调整面板宽度
static func resize_panel(panel: Control, max_width: float = 300.0, screen_fraction: float = 0.35):
	var screen_w = _get_screen_size().x
	var new_w = min(max_width, screen_w * screen_fraction)
	panel.custom_minimum_size.x = new_w

# 将节点的偏移量改为百分比锚点（适配不同分辨率）
static func anchor_fullscreen(node: CanvasItem):
	if node is Control:
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 1.0
		node.anchor_bottom = 1.0
		node.offset_left = 0.0
		node.offset_top = 0.0
		node.offset_right = 0.0
		node.offset_bottom = 0.0

# 将节点锚定到右侧，保留指定像素宽度
static func anchor_right_panel(node: Control, panel_width: float = 300.0):
	var screen_w = _get_screen_size().x
	var w = min(panel_width, screen_w * 0.4)
	node.anchor_left = 1.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = -w
	node.offset_top = 44.0  # 工具栏高度
	node.offset_right = 0.0
	node.offset_bottom = 0.0

# ========================================
# 字体缩放
# ========================================

# 根据屏幕宽度比例调整字体大小
static func scale_font(label: Label, base_size: int = 14):
	var scale = _get_screen_size().x / DESIGN_WIDTH
	label.add_theme_font_size_override("font_size", maxi(10, int(base_size * scale)))

# ========================================
# 辅助方法
# ========================================

static func _get_screen_size() -> Vector2:
	var root = Engine.get_main_loop()
	if root and root.has_method("get_root"):
		var viewport = root.get_root()
		if viewport:
			return viewport.get_visible_rect().size
	return Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)
