# ===== 调试面板 =====
# 挂载左下角，工具栏调试按钮控制开关
# 显示性能指标 + 游戏状态 + 鼠标信息
extends Control

# ===== 标签引用 =====
var _perf_label: Label     # 性能行：FPS / Memory / Nodes / Physics
var _game_label: Label     # 游戏行：Gold / Lives / Wave / Enemies / Towers
var _mouse_label: Label    # 鼠标行：Mouse pos / Tile / Keys

var _is_visible: bool = false
var _map_manager: Node = null

func _ready():
	if not OS.is_debug_build():
		queue_free()
		return
	_map_manager = get_tree().get_first_node_in_group("map_manager")
	_build_ui()
	visible = false

func _build_ui():
	# 锚点设为左下角
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_left = 8
	offset_top = -200
	offset_right = 280
	offset_bottom = -8

	# 半透明黑底
	var bg = Panel.new()
	bg.name = "Bg"
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.size_flags_horizontal = SIZE_EXPAND_FILL
	bg.size_flags_vertical = SIZE_EXPAND_FILL
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# 边距容器
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.size_flags_vertical = SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# 创建三个标签
	_perf_label = _make_label()
	vbox.add_child(_perf_label)

	var sep1 = HSeparator.new()
	sep1.modulate = Color(1, 1, 1, 0.3)
	vbox.add_child(sep1)

	_game_label = _make_label()
	vbox.add_child(_game_label)

	var sep2 = HSeparator.new()
	sep2.modulate = Color(1, 1, 1, 0.3)
	vbox.add_child(sep2)

	_mouse_label = _make_label()
	vbox.add_child(_mouse_label)

func _make_label() -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	return label

func _process(_delta):
	if not visible:
		return
	_update_perf()
	_update_game()
	_update_mouse()

func _update_perf():
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var phys = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	_perf_label.text = "FPS: %d  Mem: %.1f MB\nNodes: %d  Physics2D: %d" % [fps, mem, nodes, phys]

func _update_game():
	var gold = GameManager.gold if "gold" in GameManager else 0
	var lives = GameManager.lives if "lives" in GameManager else 0
	var wave = GameManager.wave if "wave" in GameManager else 0
	var total_wave = GameManager.total_waves if "total_waves" in GameManager else 0
	var enemies = GameManager.enemies_on_field if "enemies_on_field" in GameManager else 0
	var towers = _count_towers()
	_game_label.text = "Gold: %d  HP: %d\nWave: %d/%d  Enemies: %d\nTowers: %d" % [gold, lives, wave, total_wave, enemies, towers]

func _update_mouse():
	var mouse_pos = get_global_mouse_position()
	var tile_pos = Vector2i.ZERO
	if _get_tile_map():
		tile_pos = _get_tile_map().local_to_map(mouse_pos)
	_mouse_label.text = "Mouse: (%.0f, %.0f)\nTile: (%d, %d)" % [mouse_pos.x, mouse_pos.y, tile_pos.x, tile_pos.y]

func _get_tile_map():
	if _map_manager and _map_manager.has_method("get_tile_map"):
		return _map_manager.get_tile_map()
	return null

func _count_towers() -> int:
	if _map_manager and _map_manager.has_method("count_towers"):
		return _map_manager.count_towers()
	return 0

func toggle():
	_is_visible = not _is_visible
	visible = _is_visible