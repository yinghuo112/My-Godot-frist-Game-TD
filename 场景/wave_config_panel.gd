@tool
extends Panel

@export var waves: Array[WaveEntry] = []

@onready var export_btn: Button = %ExportBtn
@onready var status_label: Label = %StatusLabel

func _ready():
	if Engine.is_editor_hint():
		export_btn.pressed.connect(_on_export)
		if not ResourceLoader.exists("res://配置/wave_config.tres"):
			_generate_default()
	else:
		queue_free()

func _generate_default():
	var entry = WaveEntry.new()
	entry.enemy_scene = preload("res://怪物/green_monster.tscn")
	entry.count = 12
	entry.spawn_interval = 0.5
	waves = [entry]
	_on_export()

func _on_export():
	var data = WaveConfigData.new()
	data.waves = waves.duplicate()
	var result = ResourceSaver.save(data, "res://配置/wave_config.tres")
	if result == OK:
		status_label.text = "导出成功！"
	else:
		status_label.text = "导出失败: " + error_string(result)
