extends Control

signal dialogue_finished

@onready var speaker_label: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var choices_box: VBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/ChoicesBox

var typing_timer: Timer = Timer.new()
var current_text: String = ""
var typing_speed: float = 0.05

var dialogue_data: Dictionary = {}
var current_dialogue_id: String

func _ready():
	print("[DUI] _ready() start")
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)
	hide()
	load_and_start_dialogue("res://dialogue_data.json", "start")
	print("[DUI] _ready() end, visible=", visible)

func load_and_start_dialogue(file_path: String, start_id: String):
	print("[DUI] load file=", file_path, " start_id=", start_id)
	if not FileAccess.file_exists(file_path):
		push_error("[DUI] 找不到: " + file_path)
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	print("[DUI] 文件读取 ok, len=", content.length())

	var json = JSON.new()
	var error = json.parse(content)
	print("[DUI] JSON解析: error=", error, " msg=", json.get_error_message())

	if error == OK:
		var parsed_data = json.data
		print("[DUI] 解析类型=", typeof(parsed_data), " keys=", parsed_data.keys())
		if typeof(parsed_data) == TYPE_DICTIONARY:
			start(parsed_data, start_id)
		else:
			push_error("[DUI] 不是字典")
	else:
		push_error("[DUI] JSON解析失败: ", json.get_error_message())

func start(data: Dictionary, start_id: String):
	print("[DUI] start() id=", start_id, " data_size=", data.size())
	self.dialogue_data = data
	show()
	_show_dialogue(start_id)

func _show_dialogue(id: String):
	print("[DUI] _show id=", id, " has=", dialogue_data.has(id))
	if not dialogue_data.has(id):
		push_error("[DUI] 未找到ID: " + id)
		end_dialogue()
		return

	current_dialogue_id = id
	var entry = dialogue_data[id]

	speaker_label.text = entry.get("speaker", "")
	current_text = entry.get("text", "……")

	text_label.text = current_text
	text_label.visible_characters = 0

	var scrollbar = text_label.get_v_scroll_bar()
	if scrollbar:
		scrollbar.value = 0

	typing_timer.start(typing_speed)
	print("[DUI]   打字: text_len=", current_text.length(), " speaker=", entry.get("speaker",""), " choices=", entry.has("choices"), " next=", entry.has("next_id"))

	for child in choices_box.get_children():
		child.queue_free()

func _on_typing_timer_timeout():
	if text_label.visible_characters < current_text.length():
		text_label.visible_characters += 1
	else:
		typing_timer.stop()
		var entry = dialogue_data[current_dialogue_id]
		print("[DUI] 打字完成 id=", current_dialogue_id, " has_choices=", entry.has("choices"))
		if entry.has("choices"):
			_display_choices(entry["choices"])

func _display_choices(choices: Array):
	print("[DUI] _display_choices count=", choices.size())
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]["text"]
		choices_box.add_child(button)
		button.pressed.connect(_on_choice_at_index.bind(i))
		print("[DUI]   按钮[", i, "]: text=", choices[i]["text"], " next=", choices[i]["next_id"])

func _on_choice_at_index(index: int):
	print("[DUI] _on_choice_at_index index=", index, " cur_id=", current_dialogue_id)
	var entry = dialogue_data.get(current_dialogue_id, {})
	if entry.has("choices") and index < entry["choices"].size():
		var next_id = entry["choices"][index]["next_id"]
		print("[DUI]   跳转 -> ", next_id)
		_show_dialogue(next_id)
	else:
		print("[DUI]   无效: choices=", entry.has("choices"), " idx=", index, " size=", entry.get("choices",[]).size())

func _on_choice_selected(next_id: String):
	print("[DUI] _on_choice_selected next=", next_id)
	_show_dialogue(next_id)

func end_dialogue():
	print("[DUI] end_dialogue")
	hide()
	dialogue_finished.emit()

func _advance_text():
	var entry = dialogue_data.get(current_dialogue_id, {})
	print("[DUI] advance: id=", current_dialogue_id, " typing_stopped=", typing_timer.is_stopped(), " choices=", entry.has("choices"), " next=", entry.has("next_id"))
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
		print("[DUI] 输入: type=", event.get_class(), " visible=", visible, " id=", current_dialogue_id)
		if event is InputEventMouseButton and current_dialogue_id and dialogue_data.has(current_dialogue_id):
			var entry = dialogue_data[current_dialogue_id]
			if entry.has("choices"):
				print("[DUI]   阻止左键: 有选项")
				return
		_advance_text()
		get_viewport().set_input_as_handled()
