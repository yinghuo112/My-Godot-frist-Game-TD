extends Camera2D

# 边缘滚动的参数设置
@export var scroll_speed: float = 500.0   # 相机移动速度
@export var edge_margin: float = 20.0     # 触发滚动的边缘宽度（像素）

# 缩放参数设置
@export var zoom_min: float = 0.3         # 最小缩放（拉得最远）
@export var zoom_max: float = 3.0         # 最大缩放（拉得最近）
@export var zoom_step: float = 0.1        # 每次滚轮的缩放步进值
@export var zoom_speed: float = 6.0       # 缩放动画速度（平滑过渡用）

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
	
	if mouse_pos.x < edge_margin:
		move_direction.x = -1
	elif mouse_pos.x > window_size.x - edge_margin:
		move_direction.x = 1
		
	if mouse_pos.y < edge_margin:
		move_direction.y = -1
	elif mouse_pos.y > window_size.y - edge_margin:
		move_direction.y = 1
		
	if move_direction != Vector2.ZERO:
		position += move_direction.normalized() * scroll_speed * delta
	
	zoom = zoom.lerp(Vector2(_target_zoom, _target_zoom), zoom_speed * delta)


# 处理鼠标点击拖动和滚轮缩放
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = clamp(_target_zoom + zoom_step, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = clamp(_target_zoom - zoom_step, zoom_min, zoom_max)
	elif event is InputEventMouseMotion and _is_dragging:
		position -= event.relative / zoom.x
