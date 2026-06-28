extends TextureButton

func _ready():
	pressed.connect(_on_quit)

func _on_quit():
	get_tree().quit()
