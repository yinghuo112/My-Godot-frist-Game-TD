extends Resource
class_name MapData

@export var map_id: String = ""
@export var map_name: String = ""
@export var slot_names: Array[String] = []
@export var slot_positions: Array[Vector2] = []
@export var slot_difficulties: Array[float] = []

@export var is_generated: bool = false
@export var seed: int = 0
@export var grid_size: Vector2i = Vector2i(80, 56)
@export var path_style: String = "serpentine"
@export var tile_data: PackedByteArray = []
@export var path_points: PackedVector2Array = []

static func create_generated(id: String, name: String, sd: int, size: Vector2i, style: String) -> MapData:
	var d = MapData.new()
	d.map_id = id
	d.map_name = name
	d.seed = sd
	d.grid_size = size
	d.path_style = style
	d.is_generated = true
	return d
