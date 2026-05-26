@tool
extends Panel

@onready var count_input: SpinBox = %CountInput
@onready var interval_input: SpinBox = %IntervalInput
@onready var export_btn: Button = %ExportBtn
@onready var status_label: Label = %StatusLabel

func _ready():
	if Engine.is_editor_hint():
		export_btn.pressed.connect(_on_export)
		_load_from_tres()
	else:
		queue_free()

func _load_from_tres():
	if not ResourceLoader.exists("res://配置/wave_config.tres"):
		return
	var data = load("res://配置/wave_config.tres")
	if not data or data.waves.size() == 0:
		return
	var entry = data.waves[0]
	count_input.value = entry.count
	interval_input.value = entry.spawn_interval

func _on_export():
	var entry = WaveEntry.new()
	entry.enemy_scene = preload("res://怪物/green_monster.tscn")
	entry.count = int(count_input.value)
	entry.spawn_interval = interval_input.value

	var data = WaveConfigData.new()
	data.waves = [entry]
	var result = ResourceSaver.save(data, "res://配置/wave_config.tres")
	if result == OK:
		status_label.text = "导出成功！"
		print("波次配置已导出: count=%d, interval=%.1f" % [entry.count, entry.spawn_interval])
	else:
		status_label.text = "导出失败: " + error_string(result)
