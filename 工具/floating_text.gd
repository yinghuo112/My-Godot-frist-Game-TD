extends Label

func _ready():
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	add_theme_font_size_override("font_size", 20)
	size = Vector2(200, 40)

	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 40), 1.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_callback(queue_free)
