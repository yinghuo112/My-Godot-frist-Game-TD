# map_item.gd
extends Button # 或 Button

# 定义一个信号，当玩家点击这个条目时，把绑定的关卡路径发出去
signal level_selected(scene_path: String)

@onready var title_label = $TitleLabel
@onready var map_preview = $MapPreview
@onready var stars = $Panel/StartBox.get_children()

# 这是一个隐藏变量，用来记住这个按钮对应的是哪个真实的地图场景
var target_scene_path: String = ""

func _ready():
	pressed.connect(_on_pressed)

# 当主界面生成这个条目时，会调用这个方法塞入数据
func setup(level_name: String, preview_texture_path: String, star_count: int, scene_path: String):
	title_label.text = level_name
	
	# 加载并显示缩略图
	if preview_texture_path != "":
		map_preview.texture = load(preview_texture_path)
		
	# 记录真实的场景路径（比如 "res://Scene/levels/map_001.tscn"）
	target_scene_path = scene_path
	
	# 动态点亮星星
	for i in range(stars.size()):
		if i < star_count:
			stars[i].modulate = Color(1, 1, 1, 1) # 亮星
		else:
			stars[i].modulate = Color(0.3, 0.3, 0.3, 1) # 暗星（变灰）

func _on_pressed():
	# 玩家点击后，把自己的目标路径通过信号发射出去
	level_selected.emit(target_scene_path)
