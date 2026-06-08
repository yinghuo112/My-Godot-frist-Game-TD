extends TowerBase

var _triple_cooldown: float = 0.0

func _process(delta):
	if _triple_cooldown > 0:
		_triple_cooldown -= delta
	super(delta)

func _shoot():
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	_last_skills = _get_active_skills()
	var skill = _find_triple_skill(_last_skills)
	var lv = get_skill_level(skill)
	var count = 1
	if lv > 0 and _triple_cooldown <= 0:
		count = skill.get_shot_count(lv)
		_triple_cooldown = skill.get_cooldown(lv)
	AudioManager.play_shoot()
	for i in range(count):
		_fire_arrow(target)

func _fire_arrow(tgt: Node2D):
	var bullet = _bullet_manager.get_bullet(bullet_scene) if _bullet_manager else bullet_scene.instantiate()
	if not bullet:
		return
	bullet.global_position = bullet_spawn.global_position
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
