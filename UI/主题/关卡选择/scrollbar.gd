extends Control # 或者你挂载脚本的节点类型

# 这里需要把你场景树里的真实节点拖过来，替换掉引号里的路径
@onready var map_scroll = $MapScroll
@onready var custom_slider = $CustomVScrollBar/VSlider

var hidden_scrollbar: VScrollBar

func _ready():
	# 1. 获取那个被我们隐藏起来的、Godot原生的滚动条
	hidden_scrollbar = map_scroll.get_v_scroll_bar()
	
	# 2. 联动 A：当玩家用【鼠标滚轮】滑动左侧地图时，让右侧的滑块跟着动
	hidden_scrollbar.value_changed.connect(_on_hidden_scroll_changed)
	
	# 3. 联动 B：当玩家用鼠标【拖拽右侧滑块】时，让左侧的地图跟着滚
	custom_slider.value_changed.connect(_on_custom_slider_changed)

# 实时同步最大滚动距离（处理地图数量增加的情况）
func _process(_delta):
	if hidden_scrollbar:
		# 真正的最大滚动值 = 总高度 - 单页显示的高度
		custom_slider.max_value = hidden_scrollbar.max_value - hidden_scrollbar.page

func _on_hidden_scroll_changed(value: float):
	# 屏蔽反向触发，防止死循环
	if custom_slider.value != value:
		custom_slider.value = value

func _on_custom_slider_changed(value: float):
	# 屏蔽反向触发，防止死循环
	if hidden_scrollbar.value != value:
		hidden_scrollbar.value = value
