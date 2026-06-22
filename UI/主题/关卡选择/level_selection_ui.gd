# level_selection_ui.gd
extends Control

# 把你的 MapItem 场景拖到右侧检查器的这个变量里
@export var map_item_scene: PackedScene 

# 获取用来装所有条目的 VBoxContainer 容器
# 注意：根据你的截图，路径应该是 HBoxContainer/MapScroll/MapSevent
@onready var list_container = $MainPanel/HBoxContainer/MapScroll/MapSevent

var _previews = [
	"res://assets/UI/Plance_Level_select/segment_007.png",
	"res://assets/UI/Plance_Level_select/segment_008.png",
	"res://assets/UI/Plance_Level_select/segment_009.png",
	"res://assets/UI/Plance_Level_select/segment_010.png",
]

@onready var _start_btn = $TextureRect/StartButton
var map_button_group = ButtonGroup.new()
var selected_scene_path: String = ""

func _ready():
	_start_btn.pressed.connect(_on_start_game)

func _on_start_game():
	var md = MapData.create_generated("gen_" + str(Time.get_ticks_msec()), "随机地图", 0, Vector2i(80, 56), "serpentine", 8, 2, 0.3)
	MapGenerator.pending_gen = md
	get_tree().change_scene_to_file("res://tower_defense.tscn")

# 由开始界面.gd 调用，每次打开面板时刷新列表
func populate():
	for child in list_container.get_children():
		child.queue_free()
	var dir = DirAccess.open("res://Scene/levels/")
	if not dir:
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.ends_with(".tscn"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for i in range(files.size()):
		var level_name = files[i].trim_suffix(".tscn")
		var scene_path = "res://Scene/levels/" + files[i]
		var meta_path = "res://data/maps/" + level_name + ".tres"
		var md = load(meta_path) as MapData if ResourceLoader.exists(meta_path) else null
		var display = md.map_name if md and md.map_name != "" else level_name
		var preview = _previews[i % _previews.size()]
		var item = map_item_scene.instantiate()
		list_container.add_child(item)
		item.button_group = map_button_group
		item.setup(display, preview, 0, scene_path)
		item.level_selected.connect(_on_level_item_selected)
		if i == 0:
			item.button_pressed = true
			selected_scene_path = scene_path

# 当任意一个地图条目被点击时，这个函数就会被触发
func _on_level_item_selected(scene_to_load: String):
	print("当前选中的地图路径: ", scene_to_load)
	selected_scene_path = scene_to_load
