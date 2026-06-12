extends Node2D

@export var slot_scene: PackedScene = preload("res://Scene/tower_slot.tscn")
@export var debug_tower_data: TowerType = preload("res://config/test_tower.tres")

var current_map_data: MapData = null

func _ready() -> void:
	var slots_node = $TowerSlots
	if slots_node and slots_node.get_child_count() > 0:
		setup_from_saved_scene()
	else:
		generate_and_setup_level()

func generate_and_setup_level() -> void:
	var tilemap = $TileMapLayer
	if not tilemap:
		push_error("缺少 TileMapLayer 子节点")
		return

	current_map_data = MapData.new()
	current_map_data.grid_size = Vector2i(25, 15)
	current_map_data.slot_count = 6
	current_map_data.path_style = "random_walk"

	var generator = MapGenerator.new()
	var success = generator.generate(tilemap, current_map_data)

	if success:
		print("🧱 已生成地图")
		spawn_interactive_slots(current_map_data)
	else:
		print("❌ 地图生成失败")

func setup_from_saved_scene() -> void:
	var scene_path = get_scene_file_path()
	if scene_path == "":
		return
	var base = scene_path.get_file().trim_suffix(".tscn")
	var meta_path = "res://data/maps/" + base + ".tres"
	if ResourceLoader.exists(meta_path):
		current_map_data = load(meta_path) as MapData
		print("📂 加载地图：%s" % current_map_data.map_name)

	var slots_node = $TowerSlots
	if slots_node:
		for slot in slots_node.get_children():
			if slot is TowerSlot and not slot.clicked.is_connected(_on_slot_clicked):
				slot.clicked.connect(_on_slot_clicked)

func spawn_interactive_slots(md: MapData) -> void:
	for old_slot in get_tree().get_nodes_in_group("interactive_slots"):
		old_slot.queue_free()

	var tilemap = $TileMapLayer
	for i in range(md.slot_positions.size()):
		var slot_instance = slot_scene.instantiate() as TowerSlot
		slot_instance.global_position = md.slot_positions[i]
		slot_instance.name = md.slot_names[i]
		slot_instance.add_to_group("interactive_slots")
		slot_instance.clicked.connect(_on_slot_clicked)
		tilemap.add_sibling(slot_instance)

	print("🎯 已实例化 %d 个塔槽" % md.slot_positions.size())

func _on_slot_clicked(slot: TowerSlot, is_empty: bool) -> void:
	print("🖱️ 点击 [%s]  %s" % [slot.name, "空闲" if is_empty else "有塔"])

	if is_empty and debug_tower_data:
		var new_tower = debug_tower_data.scene.instantiate()
		new_tower.init(debug_tower_data)
		slot.place_tower(new_tower)
