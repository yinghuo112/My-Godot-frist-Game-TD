extends Resource
class_name MapData

@export var map_id: String = ""
@export var map_name: String = ""
@export var slot_names: Array[String] = []
@export var slot_positions: Array[Vector2] = []
@export var slot_difficulties: Array[float] = []

@export var is_generated: bool = false
@export var map_seed: int = 0
@export var grid_size: Vector2i = Vector2i(80, 56)
@export var path_style: String = "serpentine"
@export var path_width: int = 2
@export var path_coverage: float = 0.3
@export var tile_data: PackedByteArray = []
@export var path_points: PackedVector2Array = []
@export var alt_path_points: PackedVector2Array = []
@export var figure8_layout: String = ""
@export var slot_count: int = 8

static func create_generated(id: String, name: String, sd: int, size: Vector2i, style: String, slots: int = 8, pw: int = 2, cov: float = 0.3) -> MapData:
	var d = MapData.new()
	d.map_id = id
	d.map_name = name
	d.map_seed = sd
	d.grid_size = size
	d.path_style = style
	d.slot_count = slots
	d.path_width = pw
	d.path_coverage = cov
	d.is_generated = true
	return d
