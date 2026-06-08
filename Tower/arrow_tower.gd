extends TowerBase

var _triple_cd: Timer = null
var _is_triple: bool = false

func _shoot():
	if _triple_cd == null:
		_triple_cd = Timer.new()
		_triple_cd.one_shot = true
		_triple_cd.name = "TripleTimer"
		add_child(_triple_cd)

	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	_last_skills = _get_active_skills()
	var skill = _find_triple_skill(_last_skills)
	var lv = get_skill_level(skill)
	var cd_ready = skill != null and lv > 0 and _triple_cd.is_stopped()

	print(">>> _shoot triple_found=%s lv=%d cd_ready=%s" % [skill != null, lv, cd_ready])

	var count = 1
	if cd_ready:
		count = skill.get_shot_count(lv)
		_triple_cd.wait_time = skill.get_cooldown(lv)
		_triple_cd.start()
		_is_triple = true
		print(">>> 三连射 %d 箭, CD %.1fs" % [count, skill.get_cooldown(lv)])

	AudioManager.play_shoot()
	for i in range(count):
		_fire_arrow(target)
	_is_triple = false

func _fire_arrow(tgt: Node2D):
	var bullet = _bullet_manager.get_bullet(bullet_scene) if _bullet_manager else bullet_scene.instantiate()
	if not bullet:
		return
	bullet.global_position = bullet_spawn.global_position
	bullet.modulate = Color.RED if _is_triple else Color.WHITE
	bullet.initialize(tgt, _cached_damage,
		tower_type.crit_chance, tower_type.crit_multiplier,
		tower_type.hit_chance, tower_type.attack_type, self,
		_last_skills)
	for s in _last_skills:
		if s and s.has_method("on_pre_shot"):
			s.on_pre_shot(self, bullet, tgt, get_skill_level(s))
	if _tower_defense_root:
		_tower_defense_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func _find_triple_skill(skills: Array) -> TripleShotSkill:
	for s in skills:
		if s is TripleShotSkill:
			return s
	return null
