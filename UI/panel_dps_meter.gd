extends PanelContainer

var _collapsed: bool = false
var _show_all: bool = false
var _refresh_timer: Timer

@onready var header: Button = $VBox/HeaderBtn
@onready var list_container: VBoxContainer = $VBox/ListBox
@onready var toggle_btn: Button = $VBox/ToggleBtn

func _ready():
	_refresh_timer = Timer.new()
	_refresh_timer.name = "DpsRefreshTimer"
	_refresh_timer.wait_time = 0.5
	_refresh_timer.timeout.connect(_refresh)
	add_child(_refresh_timer)
	_refresh_timer.start()
	header.pressed.connect(_toggle_collapse)
	toggle_btn.pressed.connect(_toggle_all)

func _refresh():
	var towers = get_tree().get_nodes_in_group("tower")
	towers.sort_custom(func(a, b): return a.get_dps() > b.get_dps())
	for c in list_container.get_children():
		c.queue_free()
	
	# 表头行
	var hdr = HBoxContainer.new()
	hdr.custom_minimum_size.y = 18
	var mk_label = func(text: String, min_w: float, color: Color, align: int) -> Label:
		var l = Label.new()
		l.text = text
		l.custom_minimum_size.x = min_w
		l.add_theme_font_size_override("font_size", 9)
		l.add_theme_color_override("font_color", color)
		l.horizontal_alignment = align
		return l
	hdr.add_child(mk_label.call("#", 22, Color(0.5, 0.5, 0.5), 0))
	var hname = mk_label.call("名称", 0, Color(0.6, 0.6, 0.6), 0)
	hname.size_flags_horizontal = 3
	hdr.add_child(hname)
	hdr.add_child(mk_label.call("共计", 55, Color(0.8, 0.8, 0.5), 2))
	hdr.add_child(mk_label.call("实际秒伤", 50, Color(0.6, 0.8, 0.6), 2))
	hdr.add_child(mk_label.call("战斗时间", 50, Color(0.6, 0.6, 0.7), 2))
	hdr.add_child(mk_label.call("路线覆盖", 50, Color(0.5, 0.8, 0.7), 2))
	hdr.add_child(mk_label.call("参考战力", 55, Color(0.7, 0.7, 0.5), 2))
	hdr.add_child(mk_label.call("槽位难度", 45, Color(0.5, 0.7, 0.9), 2))
	hdr.add_child(mk_label.call("有效战力", 55, Color(0.8, 0.6, 0.8), 2))
	hdr.add_child(mk_label.call("峰值", 50, Color(0.5, 0.7, 0.8), 2))
	hdr.add_child(mk_label.call("现在的秒伤", 50, Color(0.8, 0.6, 0.4), 2))
	list_container.add_child(hdr)

	var count = towers.size() if _show_all else min(5, towers.size())
	for i in range(count):
		var t = towers[i]
		var row = HBoxContainer.new()
		row.custom_minimum_size.y = 18
		var idx = Label.new()
		idx.text = "#" + str(i + 1)
		idx.custom_minimum_size.x = 22
		idx.add_theme_font_size_override("font_size", 10)
		idx.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		var name_lbl = Label.new()
		name_lbl.text = t.get_tower_name() if t.has_method("get_tower_name") else "?"
		name_lbl.size_flags_horizontal = 3
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		var dmg_lbl = Label.new()
		dmg_lbl.text = str(int(t.total_damage_dealt))
		dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dmg_lbl.custom_minimum_size.x = 55
		dmg_lbl.add_theme_font_size_override("font_size", 10)
		dmg_lbl.add_theme_color_override("font_color", Color(1, 1, 0.6))
		var dps_lbl = Label.new()
		dps_lbl.text = "%.1f" % [t.get_combat_dps()]
		dps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dps_lbl.custom_minimum_size.x = 50
		dps_lbl.add_theme_font_size_override("font_size", 10)
		dps_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		var ct_lbl = Label.new()
		ct_lbl.text = "%.1fs" % [t.get_combat_time()] if t.has_method("get_combat_time") else "?"
		ct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ct_lbl.custom_minimum_size.x = 50
		ct_lbl.add_theme_font_size_override("font_size", 10)
		ct_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		var cov_lbl = Label.new()
		cov_lbl.text = "%d%%" % [t.get_path_coverage()] if t.has_method("get_path_coverage") else "?"
		cov_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cov_lbl.custom_minimum_size.x = 50
		cov_lbl.add_theme_font_size_override("font_size", 10)
		cov_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.7))
		var pw_lbl = Label.new()
		pw_lbl.text = "%.0f" % [t.tower_type.power] if t.tower_type and t.tower_type.power > 0 else "-"
		pw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pw_lbl.custom_minimum_size.x = 55
		pw_lbl.add_theme_font_size_override("font_size", 10)
		pw_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		var sd_lbl = Label.new()
		sd_lbl.text = "x%.2f" % [t.slot_difficulty]
		sd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sd_lbl.custom_minimum_size.x = 45
		sd_lbl.add_theme_font_size_override("font_size", 10)
		sd_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		var ep_lbl = Label.new()
		var eff_power = t.tower_type.power * t.slot_difficulty if t.tower_type and t.tower_type.power > 0 else 0
		ep_lbl.text = "%.0f" % [eff_power] if eff_power > 0 else "-"
		ep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ep_lbl.custom_minimum_size.x = 55
		ep_lbl.add_theme_font_size_override("font_size", 10)
		ep_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.8))
		var peak_lbl = Label.new()
		peak_lbl.text = "%.1f" % [t.get_peak_dps()]
		peak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		peak_lbl.custom_minimum_size.x = 50
		peak_lbl.add_theme_font_size_override("font_size", 10)
		peak_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		var rt_lbl = Label.new()
		rt_lbl.text = "%.1f" % [t.get_realtime_dps()]
		rt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rt_lbl.custom_minimum_size.x = 50
		rt_lbl.add_theme_font_size_override("font_size", 10)
		rt_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
		row.add_child(idx)
		row.add_child(name_lbl)
		row.add_child(dmg_lbl)
		row.add_child(dps_lbl)
		row.add_child(ct_lbl)
		row.add_child(cov_lbl)
		row.add_child(pw_lbl)
		row.add_child(sd_lbl)
		row.add_child(ep_lbl)
		row.add_child(peak_lbl)
		row.add_child(rt_lbl)
		list_container.add_child(row)
	if towers.size() > 5:
		toggle_btn.text = "显示Top5 △" if _show_all else "显示全部 ▽"
		toggle_btn.show()
	else:
		toggle_btn.hide()
	list_container.visible = not _collapsed

func _toggle_collapse():
	_collapsed = not _collapsed
	list_container.visible = not _collapsed
	toggle_btn.visible = not _collapsed
	header.text = "📊 DPS统计  " + ("▼" if _collapsed else "▲")

func _toggle_all():
	_show_all = not _show_all
	_refresh()

func dump_to_log(wave: int, session_id: int, test_type: String, debug_panel = null) -> void:
	var date_str = Time.get_date_string_from_system()
	var logs_dir = _resolve_logs_dir()

	var abs_path = logs_dir.path_join("dps_%s.csv" % [date_str])
	var lines = []
	if FileAccess.file_exists(abs_path):
		var f = FileAccess.open(abs_path, FileAccess.READ)
		if f:
			while not f.eof_reached():
				var l = f.get_line()
				if not l.is_empty():
					lines.append(l)
			f.close()

	var file = FileAccess.open(abs_path, FileAccess.WRITE)
	if not file:
		if debug_panel and debug_panel.has_method("add_log"):
			debug_panel.add_log("❌ 无法创建DPS日志文件")
		push_error("❌ 无法创建DPS日志文件: ", abs_path)
		return

	if lines.is_empty():
		file.store_line("会话,时间,波次,塔名,共计,实际秒伤,战斗时间,路线覆盖,峰值,现在的秒伤,备注")
	else:
		for l in lines:
			file.store_line(l)
	var time_str = Time.get_time_string_from_system(false)
	for t in get_tree().get_nodes_in_group("tower"):
		if not is_instance_valid(t) or not t.has_method("get_tower_name"):
			continue
		var line = "%d,%s,%d,%s,%d,%.1f,%.1fs,%d%%,%.1f,%.1f,%s" % [
			session_id, time_str, wave, t.get_tower_name(),
			int(t.total_damage_dealt),
			t.get_combat_dps(), t.get_combat_time(),
			t.get_path_coverage(),
			t.get_peak_dps(), t.get_realtime_dps(),
			test_type
		]
		file.store_line(line)
	file.close()
	var msg = "✅ DPS数据已写入 %s" % [abs_path]
	print(msg)
	if debug_panel and debug_panel.has_method("add_log"):
		debug_panel.add_log(msg)

func _resolve_logs_dir() -> String:
	var logs_dir = OS.get_user_data_dir().path_join("logs")
	if not DirAccess.dir_exists_absolute(logs_dir):
		DirAccess.make_dir_recursive_absolute(logs_dir)
	return logs_dir
