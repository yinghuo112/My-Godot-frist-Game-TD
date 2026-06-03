extends CanvasLayer

# Debug performance overlay / 性能调试面板
# Toggle: F3 key / 按 F3 开关
# Shows: FPS, memory, node count, physics / 显示帧率、内存、节点数、物理对象数

var _is_visible := true
var _labels: Dictionary = {}

func _ready():
	layer = 128
	_build_ui()
	process_mode = PROCESS_MODE_ALWAYS

func _build_ui():
	var vbox = VBoxContainer.new()
	vbox.name = "DebugOverlay"
	vbox.position = Vector2(10, 10)
	add_child(vbox)

	var items = ["FPS", "Memory", "Nodes", "Physics 2D"]

	for labelName in items:
		var label = Label.new()
		label.name = labelName
		label.add_theme_color_override("font_color", Color(0, 1, 0))
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		vbox.add_child(label)
		_labels[labelName] = label

	var hint = Label.new()
	hint.text = "[F3] Hide"
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hint.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hint)

func _process(_delta):
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	_labels["FPS"].text = "FPS: %d" % fps

	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	_labels["Memory"].text = "Memory: %.1f MB" % mem

	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_labels["Nodes"].text = "Nodes: %d" % nodes

	var phys = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	_labels["Physics 2D"].text = "Physics 2D: %d" % phys

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_is_visible = not _is_visible
		visible = _is_visible
		var hint = $DebugOverlay.get_child(-1)
		if hint is Label:
			hint.text = "[F3] Show" if not _is_visible else "[F3] Hide"
