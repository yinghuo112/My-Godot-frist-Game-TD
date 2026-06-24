extends PopupMenu

func _ready() -> void:
	add_item("普通菜单选项")
	add_check_item("复选框")
	add_icon_check_item(load("res://assets/bullet/hit/fireball_hit.png"),"图标复选")
	add_radio_check_item("单选互斥")
	add_separator()
	
	# 绑定嵌套子菜单
	add_submenu_item("打开子菜单", "普通菜单选项")
	
