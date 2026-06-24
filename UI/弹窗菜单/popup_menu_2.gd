extends PopupMenu

func _ready():
	print("脚本出发了")
	add_item("普通菜单选项")
	add_check_item("复选框")
	add_icon_check_item(load("res://assets/bullet/hit/fireball_hit.png"),"图标复选")
	add_radio_check_item("单选互斥")
	add_separator()
	
	# 绑定嵌套子菜单
	var sub_menu = PopupMenu.new()
	sub_menu.name = "普通菜单选项"
	sub_menu.add_item("子选项")
	sub_menu.add_item("子选项2")
	add_child(sub_menu)
	
	add_submenu_item("打开子菜单", "普通菜单选项")

	# 绑定点击信号
	index_pressed.connect(_on_index_pressed)

### 菜单点击回调函数
func _on_index_pressed(index:int):
	if index == 0:
		print("已经点击普通菜单项！")

### 按"U"键启动菜单
func _process(_delta):
	if Input.is_key_pressed(KEY_U) and not visible:
		position = get_viewport().get_mouse_position()
		popup()
