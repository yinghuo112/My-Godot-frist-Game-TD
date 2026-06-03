extends TowerBase

func _ready():
	super()
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _on_attack_anim_finished():
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		sprite.frame = 0
		sprite.stop()
