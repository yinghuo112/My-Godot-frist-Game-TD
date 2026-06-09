extends Camera2D

# 边缘滚动的参数设置
@export var _scroll_speed: float = 500.0   # 相机移动速度
@export var _edge_margin: float = 20.0     # 触发滚动的边缘宽度（像素）

# 缩放参数设置
@export var _zoom_min: float = 0.8         # 最小缩放（拉得最远）
@export var _zoom_max: float = 1.2         # 最大缩放（拉得最近）
@export var _zoom_step: float = 0.1        # 每次滚轮的缩放步进值
@export var _zoom_speed: float = 6.0       # 缩放动画速度（平滑过渡用）

var _target_zoom: float = 1.0
var _is_dragging: bool = false
var _map_manager: Node = null


# 初始化目标缩放值
func _ready():
	_target_zoom = zoom.x

func _get_map_manager() -> Node:
	if not _map_manager:
		_map_manager = get_tree().get_first_node_in_group("map_manager")
	return _map_manager

# 供 MobileAdapter 读取缩放范围
func get_zoom_min() -> float:
	return _zoom_min

func get_zoom_max() -> float:
	return _zoom_max


# 每帧检测鼠标边缘位置实现滚动，平滑缩放至目标值
func _process(delta):
	# 手机端用触摸拖拽，跳过鼠标边缘滚动
	if MobileAdapter.is_mobile():
		_clamp_position(get_viewport().get_visible_rect().size)
		zoom = zoom.lerp(Vector2(_target_zoom, _target_zoom), _zoom_speed * delta)
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var window_size = get_viewport().get_visible_rect().size
	var move_direction = Vector2.ZERO
	
	if mouse_pos.x < _edge_margin:
		move_direction.x = -1
	elif mouse_pos.x > window_size.x - _edge_margin:
		move_direction.x = 1
		
	if mouse_pos.y < _edge_margin:
		move_direction.y = -1
	elif mouse_pos.y > window_size.y - _edge_margin:
		move_direction.y = 1
		
	if move_direction != Vector2.ZERO:
		position += move_direction.normalized() * _scroll_speed * delta
	
	_clamp_position(window_size)
	
	zoom = zoom.lerp(Vector2(_target_zoom, _target_zoom), _zoom_speed * delta)


# 将相机位置限制在 play_area 内
func _clamp_position(window_size: Vector2):
	var mm = _get_map_manager()
	if not mm or mm.play_area.size == Vector2.ZERO:
		return
	var pa = mm.play_area
	var half_w = window_size.x / (2.0 * zoom.x)
	var half_h = window_size.y / (2.0 * zoom.y)
	position.x = clamp(position.x, pa.position.x + half_w, pa.end.x - half_w)
	position.y = clamp(position.y, pa.position.y + half_h, pa.end.y - half_h)


# 处理鼠标点击拖动和滚轮缩放
func _unhandled_input(event: InputEvent):
	# 手机端用触摸拖拽，跳过鼠标逻辑
	if MobileAdapter.is_mobile():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = clamp(_target_zoom + _zoom_step, _zoom_min, _zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = clamp(_target_zoom - _zoom_step, _zoom_min, _zoom_max)
	elif event is InputEventMouseMotion and _is_dragging:
		position -= event.relative / zoom.x
