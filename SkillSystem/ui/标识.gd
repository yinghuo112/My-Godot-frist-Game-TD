@tool # 1. 必须添加 @tool 才能在编辑器中运行
extends RichTextLabel

@export var 图片: Texture2D:
	set(value):
		图片 = value
		_update_display() # 2. 在属性 setter 中直接调用更新

@export var 图片大小: Vector2 = Vector2(64, 64):
	set(value):
		图片大小 = value
		_update_display()

func _ready():
	_update_display()

func _update_display():
	# 检查是否在场景树中，避免编辑器报错
	if not is_inside_tree():
		return
		
	clear()
	if 图片:
		# add_image 参数要求为 int，这里确保类型正确
		add_image(图片, int(图片大小.x), int(图片大小.y))
		add_text(" 文字内容")
	else:
		add_text("请分配一个图片资源")
