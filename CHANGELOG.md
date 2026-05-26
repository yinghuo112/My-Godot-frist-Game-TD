# project backup log

2026-05-20 14:06
backup location: D:\Administrator\Desktop\first-游戏_备份_20260520_140644
backup method: Copy-Item -Recurse (full directory)

## current project state (after refactor)

### architecture — base classes (root level)
- **enemy_base.gd** (class_name Enemy, extends PathFollow2D) — movement, HP, flip, signals `died`/`reached_end`
- **enemy_base.tscn** — PathFollow2D + AnimatedSprite2D + Area2D(groups=["enemy"]) + CollisionShape2D
- **tower_base.gd** (extends Node2D) — range detection, auto-targeting via area.get_parent(), bullet spawn
- **camera_2d.gd** (extends Camera2D) — edge-scrolling camera, used by Camera2D node in scene

### derived/concrete files
- **green_monster.tscn** — extends enemy_base.tscn, 8-frame walk animation (res://assets/jingling/64_64_*.png)
- **scenes/tower.tscn** — uses tower_base.gd, Node2D + RangeArea + ShootTimer + BulletSpawn
- **scenes/bullet.tscn** — Area2D + Sprite2D, independent tracking projectile
- **scripts/game_manager.gd** — autoload singleton, spawns green_monster under EnemyPath
- **scripts/main.gd** — UI updates, tower placement at Marker2D slots

### deleted old files
- scripts/enemy.gd — replaced by enemy_base.gd architecture
- scripts/tower.gd — replaced by tower_base.gd architecture
- scenes/enemy.tscn — replaced by green_monster.tscn

### configuration
- project.godot: main_scene = tower_defense.tscn, autoload GameManager enabled
- MCP plugin (addons/godot_ai/) installed and enabled

### notes
- path_follow_2d.gd preserved but orphaned (no longer referenced by any scene)
- TowerSlots positions: Slot1(1000,80), Slot2(87,236), Slot3(91,313), Slot4(221,273), Slot5(1000,293)
