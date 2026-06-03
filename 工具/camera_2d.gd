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


# 初始化目标缩放值
func _ready():
	_target_zoom = zoom.x


# 每帧检测鼠标边缘位置实现滚动，平滑缩放至目标值
func _process(delta):
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
	if GameManager.play_area.size == Vector2.ZERO:
		return
	var half_w = window_size.x / (2.0 * zoom.x)
	var half_h = window_size.y / (2.0 * zoom.y)
	position.x = clamp(position.x, GameManager.play_area.position.x + half_w, GameManager.play_area.end.x - half_w)
	position.y = clamp(position.y, GameManager.play_area.position.y + half_h, GameManager.play_area.end.y - half_h)


# 处理鼠标点击拖动和滚轮缩放
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = clamp(_target_zoom + _zoom_step, _zoom_min, _zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = clamp(_target_zoom - _zoom_step, _zoom_min, _zoom_max)
	elif event is InputEventMouseMotion and _is_dragging:
		position -= event.relative / zoom.x
