extends PanelContainer

const PANEL_WIDTH: float = 340.0

var _target_tower: Node2D = null
var _tween: Tween = null
var _is_open: bool = false

signal closed()

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var skill_container: VBoxContainer = %SkillContainer
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	close_btn.pressed.connect(_close)

func show_for_tower(tower: Node2D) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_target_tower = tower
	_populate(tower)
	visible = true
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "offset_left", 0.0, 0.3)
	_is_open = true

func _close() -> void:
	if not _is_open:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "offset_left", PANEL_WIDTH + 20.0, 0.25)
	_tween.tween_callback(func():
		visible = false
		_is_open = false
		closed.emit()
	)

func close() -> void:
	_close()

func hide_instantly() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	offset_left = PANEL_WIDTH + 20.0
	visible = false
	_is_open = false

func _populate(tower: Node2D) -> void:
	for c in skill_container.get_children():
		c.queue_free()

	var tt = tower.get("tower_type") if "tower_type" in tower else null
	if not tt:
		return
	var sb = tt.get("skill_book")
	if not sb:
		info_label.text = "该塔没有技能书。"
		return

	var unlocked: Array = tower.get("skill_unlocked_indices") if "skill_unlocked_indices" in tower else []
	var states: Dictionary = tower.get("skill_states") if "skill_states" in tower else {}
	var skill_points: int = tower.get("skill_points") if "skill_points" in tower else 0

	title_label.text = "技能书: %s" % sb.name
	info_label.text = "技能点: %d  |  已解锁: %d/%d" % [skill_points, unlocked.size(), sb.skills.size()]

	for i in sb.skills.size():
		var skill = sb.skills[i]
		var is_unlocked = i in unlocked
		var state = states.get(skill.resource_path, {"level": 0, "proficiency": 0})
		var current_level = state.get("level", 0) if is_unlocked else 0
		var card = _create_skill_card(sb, i, skill, is_unlocked, current_level, state, tower, skill_points)
		skill_container.add_child(card)

func _create_skill_card(book, idx: int, skill,
		is_unlocked: bool, level: int, state: Dictionary,
		tower: Node2D, skill_points: int) -> PanelContainer:

	var card = PanelContainer.new()
	card.custom_minimum_size.y = 60
	var bg = StyleBoxFlat.new()
	if is_unlocked:
		bg.bg_color = Color(0.15, 0.25, 0.15, 0.9)
	elif _can_unlock(book, idx, skill, tower, skill_points, level):
		bg.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	else:
		bg.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_right = 6
	bg.corner_radius_bottom_left = 6
	card.add_theme_stylebox_override("panel", bg)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var hbox = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = skill.name
	name_label.add_theme_font_size_override("font_size", 15)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hbox.add_child(name_label)

	var lv_label = Label.new()
	if is_unlocked:
		lv_label.text = " Lv.%d/%d" % [level, skill.max_level]
		lv_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	else:
		lv_label.text = " [锁定]"
		lv_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(lv_label)

	var action_btn = Button.new()
	action_btn.custom_minimum_size.x = 60
	action_btn.custom_minimum_size.y = 24

	if is_unlocked and level < skill.max_level:
		var cost_points = skill.get_cost_points(level + 1)
		var cost_prof = skill.get_cost_proficiency(level + 1)
		if skill_points >= cost_points and state.get("proficiency", 0) >= cost_prof:
			action_btn.text = "升级"
			action_btn.disabled = false
			action_btn.pressed.connect(_on_upgrade_skill.bind(tower, idx))
		else:
			action_btn.text = "需求不足"
			action_btn.disabled = true
	elif not is_unlocked:
		if _can_unlock(book, idx, skill, tower, skill_points, level):
			action_btn.text = "解锁(%dg)" % skill.gold_cost
			action_btn.disabled = false
			action_btn.pressed.connect(_on_unlock_skill.bind(tower, idx))
		else:
			action_btn.text = _get_lock_reason(book, idx, skill, tower, skill_points)
			action_btn.disabled = true
	else:
		action_btn.text = "已满级"
		action_btn.disabled = true
	hbox.add_child(action_btn)
	vbox.add_child(hbox)

	var info_hbox = HBoxContainer.new()
	var prereq_text = book.get_prerequisite_names(idx)
	if prereq_text != "":
		var prereq_label = Label.new()
		prereq_label.text = "前置: %s" % prereq_text
		prereq_label.add_theme_font_size_override("font_size", 11)
		prereq_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
		info_hbox.add_child(prereq_label)
	if is_unlocked:
		var prof_label = Label.new()
		prof_label.text = "熟练度: %d" % state.get("proficiency", 0)
		prof_label.add_theme_font_size_override("font_size", 11)
		prof_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info_hbox.add_child(prof_label)
	vbox.add_child(info_hbox)

	if is_unlocked and level < skill.max_level:
		var next_level = level + 1
		var cost_points = skill.get_cost_points(next_level)
		var cost_prof = skill.get_cost_proficiency(next_level)
		var req_label = Label.new()
		req_label.text = "升Lv.%d 需要: 技能点×%d  熟练度≥%d" % [next_level, cost_points, cost_prof]
		req_label.add_theme_font_size_override("font_size", 11)
		req_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		vbox.add_child(req_label)

	card.add_child(vbox)
	return card

func _can_unlock(book, idx: int, skill, tower: Node2D, skill_points: int, current_level: int) -> bool:
	if current_level > 0:
		return false
	if skill.gold_cost > GameManager.gold:
		return false
	var t_unlocked = tower.get("skill_unlocked_indices") if "skill_unlocked_indices" in tower else []
	if not book.are_prerequisites_met(idx, t_unlocked):
		return false
	var t_level = tower.get("level") if "level" in tower else 0
	if t_level < skill.required_tower_level:
		return false
	if skill_points < skill.get_cost_points(1):
		return false
	return true

func _get_lock_reason(book, idx: int, skill, tower: Node2D, skill_points: int) -> String:
	var t_level2 = tower.get("level") if "level" in tower else 0
	if t_level2 < skill.required_tower_level:
		return "Lv.%d" % skill.required_tower_level
	var t_unlocked2 = tower.get("skill_unlocked_indices") if "skill_unlocked_indices" in tower else []
	if not book.are_prerequisites_met(idx, t_unlocked2):
		return "前置"
	if skill.gold_cost > GameManager.gold:
		return "缺金"
	if skill_points < skill.get_cost_points(1):
		return "缺技能点"
	return "锁定"

func _on_unlock_skill(tower: Node2D, skill_idx: int) -> void:
	if not is_instance_valid(tower):
		return
	var tt = tower.get("tower_type")
	if not tt:
		return
	var sb = tt.get("skill_book")
	if not sb:
		return
	var skill = sb.skills[skill_idx]
	if not GameManager.spend_gold(skill.gold_cost):
		return
	var sp = tower.get("skill_points") if "skill_points" in tower else 0
	if sp > 0:
		tower.skill_points = sp - skill.get_cost_points(1)
	var unlocked: Array = tower.get("skill_unlocked_indices") if "skill_unlocked_indices" in tower else []
	if not skill_idx in unlocked:
		unlocked.append(skill_idx)
		tower.skill_unlocked_indices = unlocked
	var states: Dictionary = tower.get("skill_states") if "skill_states" in tower else {}
	states[skill.resource_path] = {"level": 1, "proficiency": 0}
	tower.skill_states = states
	_populate(tower)

func _on_upgrade_skill(tower: Node2D, skill_idx: int) -> void:
	if not is_instance_valid(tower):
		return
	var tt = tower.get("tower_type")
	if not tt:
		return
	var sb = tt.get("skill_book")
	if not sb:
		return
	var skill = sb.skills[skill_idx]
	var states: Dictionary = tower.get("skill_states") if "skill_states" in tower else {}
	var path = skill.resource_path
	if not path in states:
		return
	var state = states[path]
	var next_level = state.level + 1
	if next_level > skill.max_level:
		return
	var cost_points = skill.get_cost_points(next_level)
	var cost_prof = skill.get_cost_proficiency(next_level)
	var sp = tower.get("skill_points") if "skill_points" in tower else 0
	if sp >= cost_points and state.proficiency >= cost_prof:
		tower.skill_points = sp - cost_points
		state.proficiency -= cost_prof
		state.level = next_level
		states[path] = state
		tower.skill_states = states
		_populate(tower)

func _input(event: InputEvent) -> void:
	if _is_open and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()
