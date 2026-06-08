class_name SkillBook
extends Resource

# ===== 技能书属性（在 .tres 文件中配置）=====
@export var name: String = ""        # 技能书名称
@export var tags: Array = []         # 技能书标签
@export var skills: Array = []       # SkillBase 数组，按索引排列（索引 0 = 根技能，自动解锁）

# ===== 前置条件查询 =====

# 获取所有根技能（无前置条件的技能）的索引列表
func get_root_skills() -> Array:
	var roots: Array = []
	for i in skills.size():
		if skills[i].prerequisites.is_empty():
			roots.append(i)
	return roots

# 检查指定索引技能的前置条件是否都已解锁
func are_prerequisites_met(index: int, unlocked_indices: Array) -> bool:
	if index < 0 or index >= skills.size():
		return false
	var skill = skills[index]
	for prereq_idx in skill.prerequisites:
		if not prereq_idx in unlocked_indices:
			return false
	return true

# 获取当前可解锁的技能索引列表（满足塔等级 + 前置条件 + 未解锁）
func get_available_skills(tower_level: int, unlocked_indices: Array) -> Array:
	var available: Array = []
	for i in skills.size():
		if i in unlocked_indices:
			continue
		var skill = skills[i]
		if tower_level < skill.required_tower_level:
			continue
		if not are_prerequisites_met(i, unlocked_indices):
			continue
		available.append(i)
	return available

# 检查技能是否已解锁
func is_skill_unlocked(index: int, unlocked_indices: Array) -> bool:
	return index in unlocked_indices

# 获取前置技能的名称文本（用于 UI 显示）
func get_prerequisite_names(index: int) -> String:
	if index < 0 or index >= skills.size():
		return ""
	var skill = skills[index]
	if skill.prerequisites.is_empty():
		return ""
	var names: Array = []
	for idx in skill.prerequisites:
		if idx >= 0 and idx < skills.size():
			names.append(skills[idx].name)
	return ", ".join(names)
