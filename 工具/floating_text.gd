extends Label

enum Mode { FLOAT, COUNTDOWN }

var mode: Mode = Mode.FLOAT
var float_direction: Vector2 = Vector2(0, -40)

# 初始化浮动提示文字：设置样式、颜色、大小
func _ready():
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 20)
	custom_minimum_size = Vector2(200, 40)

	if not has_theme_color_override("font_color"):
		if mode == Mode.FLOAT:
			add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))

	if mode == Mode.FLOAT:
		var tween = create_tween()
		tween.tween_property(self, "position", position + float_direction, 1.2)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)
		tween.tween_callback(queue_free)
