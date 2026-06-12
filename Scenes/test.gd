extends Node2D # 或者是 Node, Panel 等，保持你原本的第一行不变

# 【关键】定义你的地图变量
var tilemap_layer: TileMapLayer

func _ready() -> void:
	# 游戏启动时，自动抓取场景里的地图节点
	# 请把 "TileMapLayer" 改成你左侧场景树里地图节点的实际名字！
	tilemap_layer = get_node("TileMapLayer") 

# 当玩家鼠标点击屏幕时，Godot 会自动触发这个内置函数
func _input(event: InputEvent) -> void:
	# 检查玩家是不是按下了【鼠标左键】
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 1. 获取鼠标在游戏世界里的绝对坐标
		var global_click_pos = get_global_mouse_position()
		
		# 2. 【核心】把鼠标的像素坐标，转换成地图的网格坐标（比如第 5 行第 3 列）
		var local_pos = tilemap_layer.to_local(global_click_pos)
		var map_cell = tilemap_layer.local_to_map(local_pos)
		
		# 3. 抓取这个格子的数据对象
		var tile_data = tilemap_layer.get_cell_tile_data(map_cell)
		
		# 如果点到了有瓷砖的地方
		if tile_data:
			# 4. 【神级联通】直接读取你在底部面板亲手刷上去的“中文名字”属性！
			# 🚨 警告：这里的名字必须跟你之前在右侧检查器里起的名字一模一样（比如叫"塔槽"就写"塔槽"，叫"can_build"就写"can_build"）
			var can_build_here = tile_data.get_custom_data("塔槽")
			var grass = tile_data.get_custom_data("草皮")
			var path = tile_data.get_custom_data("怪物路径")
			
			if can_build_here == true:
				print("🎯 检查成功！这里是你刷过数据的塔槽，可以放塔！")
				# 这里可以调用你写好的放塔函数，比如 spawn_tower(global_click_pos)
			elif grass == true:
				print("这里是草皮！")
			elif path == true:
				print("这里是怪物路径！")
		else:
			print("💨 你点到了虚无的虚空（地图外）")
