extends PanelContainer

signal link_clicked(url: String)
signal popup_closed

@onready var title_label = %TitleLabel
@onready var content = %ContentLabel
@onready var close_btn = %CloseBtn

func _ready():
	close_btn.pressed.connect(_on_close)
	content.meta_clicked.connect(_on_link)

func show_popup(title: String, content_text: String):
	title_label.text = title
	content.text = content_text
	show()

func _on_link(url: String):
	link_clicked.emit(url)

func _on_close():
	popup_closed.emit()
	hide()