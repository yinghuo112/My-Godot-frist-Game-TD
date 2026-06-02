class_name SkillBook
extends Resource

@export var name: String = ""
@export var tags: Array = []
@export var skills: Array = []

func get_root_skills() -> Array:
	var roots: Array = []
	for i in skills.size():
		if skills[i].prerequisites.is_empty():
			roots.append(i)
	return roots

func are_prerequisites_met(index: int, unlocked_indices: Array) -> bool:
	if index < 0 or index >= skills.size():
		return false
	var skill = skills[index]
	for prereq_idx in skill.prerequisites:
		if not prereq_idx in unlocked_indices:
			return false
	return true

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

func is_skill_unlocked(index: int, unlocked_indices: Array) -> bool:
	return index in unlocked_indices

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
