class_name TripleShotSkill
extends SkillBase

# 获取指定等级的冷却时间
func get_cooldown(level: int) -> float:
	return get_level_data(level).get("cooldown", 6.0)

# 获取指定等级的爆发箭数
func get_shot_count(level: int) -> int:
	return get_level_data(level).get("shot_count", 3)

# 技能面板描述（BBCode 格式）
func get_bbcode_description(level: int = 1) -> String:
	var cd = get_cooldown(level)
	var n = get_shot_count(level)
	var desc = "[b]%s[/b]" % name
	desc += "\n下一次攻击同时射出 %d 箭。" % n
	desc += "\n冷却时间: [color=yellow]%.1fs[/color]" % cd
	return desc
