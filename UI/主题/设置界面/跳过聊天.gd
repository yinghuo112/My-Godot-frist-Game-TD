extends CheckButton

func _ready():
	button_pressed = GameManager.skip_chat
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool):
	GameManager.save_skip_chat(toggled_on)
