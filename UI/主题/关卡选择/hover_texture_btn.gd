extends TextureButton

func _ready():
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_hover_end)

func _on_hover():
	modulate = get_theme_color("hover_modulate", "LevelSelectBtn")

func _on_hover_end():
	modulate = Color.WHITE
