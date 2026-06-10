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
