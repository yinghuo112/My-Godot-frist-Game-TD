extends Control

# 自定义信号：对话结束，向外传递事件
signal dialogue_finished

# 节点绑定 (注意：这里将 text_label 改为了 RichTextLabel 以支持滚动条)
@onready var speaker_label: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var choices_box: VBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/ChoicesBox

# 打字机效果配置
var typing_timer: Timer = Timer.new()
var current_text: String = ""
var typing_speed: float = 0.05

# 全局对话数据与当前剧情ID
var dialogue_data: Dictionary = {}
var current_dialogue_id: String

func _ready():
	# 1. 绑定计时器信号并隐藏界面 (保留你之前的代码)
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)
	hide()
	
	# 2. 游戏开始，立刻读取 JSON 并启动对话
	load_and_start_dialogue("res://dialogue_data.json", "start")

# 新增一个专门用来加载和启动的辅助函数
func load_and_start_dialogue(file_path: String, start_id: String):
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("找不到对话配置文件: " + file_path)
		return
		
	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# 解析 JSON
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		# 获取解析后的字典数据
		var parsed_data = json.data
		
		# 确保解析出来的是字典 (因为你的系统是基于 ID 键值对的)
		if typeof(parsed_data) == TYPE_DICTIONARY:
			# 调用原本留好的外部接口启动对话
			start(parsed_data, start_id)
		else:
			push_error("JSON 格式错误：最外层必须是字典 (Object)，而不是数组 (Array)。")
	else:
		push_error("JSON 解析失败: ", json.get_error_message(), " 在第 ", json.get_error_line(), " 行")

# ==================== 公共对外接口 ====================
func start(data: Dictionary, start_id: String):
	self.dialogue_data = data
	show()
	_show_dialogue(start_id)

# ==================== 私有核心逻辑 ====================
func _show_dialogue(id: String):
	if not dialogue_data.has(id):
		push_error("对话系统错误：未找到对话 ID：" + id)
		end_dialogue()
		return
		
	current_dialogue_id = id
	var entry = dialogue_data[id]
	
	speaker_label.text = entry.get("speaker", "")
	current_text = entry.get("text", "……")
	
	# 初始化打字机效果
	text_label.text = current_text
	text_label.visible_characters = 0
	
	# 每次新对话，确保滚动条回到顶部 (防止上一句长文本的影响)
	var scrollbar = text_label.get_v_scroll_bar()
	if scrollbar:
		scrollbar.value = 0
		
	typing_timer.start(typing_speed)
	
	for child in choices_box.get_children():
		child.queue_free()

func _on_typing_timer_timeout():
	if text_label.visible_characters < current_text.length():
		text_label.visible_characters += 1
	else:
		# 文本播放完成，停止计时器
		typing_timer.stop()
		var entry = dialogue_data[current_dialogue_id]
		
		# 打字结束后，只负责显示选项。跳转下一句的逻辑移交给了输入事件。
		if entry.has("choices"):
			_display_choices(entry["choices"])

func _display_choices(choices: Array):
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]["text"]
		choices_box.add_child(button)
		button.pressed.connect(_on_choice_at_index.bind(i))

func _on_choice_at_index(index: int):
	var entry = dialogue_data[current_dialogue_id]
	if entry.has("choices") and index < entry["choices"].size():
		_show_dialogue(entry["choices"][index]["next_id"])

func _on_choice_selected(next_id: String):
	_show_dialogue(next_id)

func end_dialogue():
	hide()
	dialogue_finished.emit()

# ==================== 输入控制 ====================
func _advance_text():
	var entry = dialogue_data.get(current_dialogue_id, {})
	if typing_timer.is_stopped():
		if entry.has("choices"):
			return
		elif entry.has("next_id"):
			_show_dialogue(entry["next_id"])
		else:
			end_dialogue()
	else:
		typing_timer.stop()
		text_label.visible_characters = current_text.length()
		_on_typing_timer_timeout()

func _unhandled_input(event: InputEvent):
	if not is_visible():
		return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if event is InputEventMouseButton and current_dialogue_id and dialogue_data.has(current_dialogue_id):
			var entry = dialogue_data[current_dialogue_id]
			if entry.has("choices"):
				return
		_advance_text()
		get_viewport().set_input_as_handled()
