extends TowerBase

func _ready():
	super()
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _shoot():
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	AudioManager.play_shoot()
	var bullet = _bullet_manager.get_bullet(bullet_scene) if _bullet_manager else bullet_scene.instantiate()
	if not bullet:
		return
	bullet.global_position = bullet_spawn.global_position
	_last_skills = _get_active_skills()
	if bullet.has_method("初始化"):
		bullet.初始化(bullet_spawn.global_position, target, _cached_damage,
			tower_type.chain_jumps, tower_type.chain_falloff, tower_type.chain_range, self, _last_skills)
	else:
		bullet.initialize(target, _cached_damage,
			tower_type.crit_chance, tower_type.crit_mult,
			tower_type.hit_chance, tower_type.attack_type, self, _last_skills)
	for s in _last_skills:
		if s and s.has_method("on_pre_shot"):
			s.on_pre_shot(self, bullet, target, get_skill_level(s))
	if _tower_defense_root:
		_tower_defense_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func _on_attack_anim_finished():
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		sprite.frame = 0
		sprite.stop()
