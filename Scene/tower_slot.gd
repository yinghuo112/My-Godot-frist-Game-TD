extends Node2D
class_name TowerSlot

signal clicked(slot: TowerSlot, is_empty: bool)

var _tower: Node2D = null

@onready var _visual: Sprite2D = $Visual
@onready var _area: Area2D = $ClickArea

func _ready():
	_area.input_event.connect(_on_area_input)

	if _visual and _visual.texture:
		_visual.texture_filter = TEXTURE_FILTER_NEAREST
	unhighlight()

func is_empty() -> bool:
	return _tower == null or not is_instance_valid(_tower)

func get_tower() -> Node2D:
	return _tower if is_instance_valid(_tower) else null

func place_tower(tower: Node2D) -> void:
	_tower = tower
	add_child(tower)
	tower.position = Vector2.ZERO
	_visual.hide()
	unhighlight()
	print("🎯 槽位成功挂载大塔节点：", tower.name)

func remove_tower() -> void:
	if _tower and is_instance_valid(_tower):
		_tower.queue_free()
	_tower = null
	_visual.show()
	unhighlight()

func highlight() -> void:
	_visual.modulate = Color(1, 1, 1, 0.8)

func unhighlight() -> void:
	_visual.modulate = Color(1, 1, 1, 0.35)

func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self, is_empty())
		get_viewport().set_input_as_handled()
