extends TowerBase

func _ready():
	super()
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	shoot_timer.stop()
	if shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.disconnect(_on_shoot_timer_timeout)
	shoot_timer.timeout.connect(_on_snow_timer)
	shoot_timer.wait_time = _cached_fire_rate
	shoot_timer.start()

var _pending_attack: bool = false

func init(data):
	super(data)

func _process(delta):
	if _combat_timeout > 0:
		_combat_time += delta
		_combat_timeout -= delta
	_combat_timeout = max(_combat_timeout, 0.0)

func _on_snow_timer():
	if _pending_attack:
		return
	var enemies = get_tree().get_nodes_in_group("enemy")
	var has_target = false
	for area in enemies:
		if is_instance_valid(area) and area.get_parent() and area.get_parent().has_method("take_damage"):
			has_target = true
			break
	if has_target:
		_start_attack()

func _start_attack():
	_combat_timeout = 2.0
	_pending_attack = true
	_last_skills = _get_active_skills()
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

func _fire_snowball():
	var bullet = _bullet_manager.get_bullet(bullet_scene) if _bullet_manager else bullet_scene.instantiate()
	if not bullet:
		return
	bullet.global_position = bullet_spawn.global_position
	if _tower_defense_root:
		_tower_defense_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)
	bullet.initialize(null, _cached_damage,
		tower_type.crit_chance, tower_type.crit_mult,
		tower_type.hit_chance, tower_type.attack_type, self,
		_last_skills)
	for s in _last_skills:
		if s and s.has_method("on_pre_shot"):
			s.on_pre_shot(self, bullet, null, get_skill_level(s))

func _on_attack_anim_finished():
	if not _pending_attack:
		return
	_fire_snowball()
	_pending_attack = false
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		sprite.frame = 0
		sprite.stop()
