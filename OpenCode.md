# Project Context — 2D Tower Defense (Godot 4.6.2)

## Info
- Path: `D:\Administrator\Game\first-游戏\`
- GitHub: `https://github.com/yinghuo112/My-Godot-frist-Game-TD.git`
- Main scene: `res://场景/StartScreen.tscn`
- Game scene: `res://tower_defense.tscn`
- Engine: Godot 4.6.2
- All `.gd`/`.tscn` files: **UTF-8 without BOM**

## Autoloads
| Name | Path |
|------|------|
| `GameManager` | `res://核心/game_manager.gd` |
| `AudioManager` | `res://核心/audio_manager.gd` |
| `_mcp_game_helper` | `res://addons/godot_ai/runtime/game_helper.gd` |

## Architecture

### Core Files
| File | What it does |
|------|-------------|
| `核心/main.gd` (extends Node2D) | Tower placement, wave start, UI updates, tree system, input handling (`_input` + `_unhandled_input`) |
| `核心/game_manager.gd` (Node autoload) | Gold/lives/wave state, batch enemy spawn, config load, signals |
| `核心/bullet.gd` (extends Area2D) | Homing projectile, proximity hit (<12px) + `area_entered` with `"enemy"` group |
| `核心/audio_manager.gd` (Node autoload) | BGM (`音乐/BJ_TD.mp3`), placeholder SFX, volume persist via ConfigFile |
| `核心/settings_panel.gd` | Fullscreen toggle, music/sfx volume, pause |
| `核心/start_screen.gd` | Start screen (开始游戏/关卡选择/设置/退出) |
| `核心/level_select_panel.gd` | Level select dialog |

### Enemy System
| File | What it does |
|------|-------------|
| `怪物/enemy_base.gd` (class_name Enemy, extends PathFollow2D) | Path following, HP, overtaking (RayCast2D + lane-change state machine), `died`/`reached_end` signals |
| `怪物/enemy_base.tscn` | Base with Area2D (group `"enemy"`), RayCast2D, ProgressBar |
| `怪物/green_monster.tscn` | Instance of enemy_base with AnimatedSprite2D |
| `怪物/green_monster02.tscn` | Variant |

### Tower System
| File | What it does |
|------|-------------|
| `防御塔/tower_base.gd` (class_name TowerBase, extends Node2D) | RangeArea detection, target priority (enemy > marked tree), shoot timer, upgrade system (Lv.1-3, multipliers: dmg×1.5, fr×0.85, range×1.1) |
| `防御塔/tower_base.tscn` | Base: RangeArea + CollisionShape2D + ShootTimer + BulletSpawn |
| `防御塔/TowerActionRing.tscn` | Ring menu (升级/出售/信息) + InfoPopupPanel child |
| `防御塔/tower_action_ring.gd` | Ring logic, shared InfoPopupPanel, _show_floating_text ("金币不足。。") |
| `scenes/ArrowTower.tscn` | Instance of tower_base with AnimatedSprite2D |

### UI
| File | What it does |
|------|-------------|
| `场景/StartScreen.tscn` | Main menu (title + buttons + SettingsPanel + LevelSelectPanel) |
| `场景/SettingsPanel.tscn` | Settings overlay (reused in both StartScreen and game) |
| `场景/LevelSelectPanel.tscn` | Level select popup |

### Camera
| File | What it does |
|------|-------------|
| `工具/camera_2d.gd` (extends Camera2D) | Edge scroll + right-click drag + wheel zoom (lerp) |

### Tree System
| File | What it does |
|------|-------------|
| `树/tree.gd` (class_name GameTree, extends Node2D) | 2 stages: SAPLING→MATURE (15s), HP=30, mark/unmark for tower attack, take_damage/die, Area2D on collision_layer=2 |
| `树/Tree.tscn` | Scene: ColorRect + Area2D(layer2) + CollisionShape2D + GrowTimer |

### Config
| File | What it does |
|------|-------------|
| `配置/wave_config.tres` | Wave data (2 entries, fallback repeats last) |
| `配置/wave_entry.gd` | Resource class: enemy_scene, count, spawn_interval |
| `配置/wave_config_data.gd` | Resource class: array of WaveEntry |

## Key Technical Details

### Input Pipeline (main.gd)
- `_input()` → tower slot clicks (before GUI). If `tower_ring.visible`, skip. Then tree clicks.
- `_unhandled_input()` → close ring on empty-space click

### Tower Targeting (tower_base.gd)
- `_on_area_entered` checks `"enemy"` group + `parent is GameTree`
- Priority: real enemy > marked tree
- `range_area.collision_mask |= 2` to detect tree layer
- Tower Area2D: default layer 1 (enemies). Tree Area2D: layer 2.

### Bullet
- `collision_mask |= 2` in _ready (hits tree layer 2)
- Hit via: `distance < 12px` (tracking) OR `area_entered` with `"enemy"` group
- Calls `target.has_method("take_damage")` → tree has it

### Floating Text (金币不足。。)
- In `tower_action_ring.gd._show_floating_text()`
- Creates `Label.new()` with explicit `size = Vector2(200, 40)`, screen-space position, Tween mod fade

### Tree Spawning (main.gd)
- Timer starts 3s after _ready, repeats 8-15s
- Finds grass cell (source_id=0) via TileMapLayer.get_used_cells()
- Validates: not on tower slot (dist²<1600), not on path (baked points dist²<1600), not overlapping other tree (dist²<2500)
- Max 8 trees. Sapling 15s → Mature. Click to mark/unmark. Tower attacks when marked.

### Tree Growth (tree.gd)
- States: SAPLING (green 24x24) → MATURE (brown 40x40) at 15s
- `mark()`: monitoring=true, add_to_group("enemy"), modulate orange
- `unmark()`: monitoring=false, remove_from_group("enemy"), modulate white
- `take_damage()`: visual color fades from brown to red as HP drops
- `die()`: emit `died(reward)`, queue_free

### Overtaking (enemy_base.gd)
- RayCast2D detects front enemy. If self faster → lane-change (v_offset ±40px). Else follow front speed.

## Rules & Constraints

### Workflow Rules
- **Never commit or push unless explicitly told**. Wait for the exact words.
- Use `distance_squared_to()` instead of `distance_to()` for perf
- Tower click detection uses `_unhandled_input` to avoid camera drag conflict
- TowerActionRing has `mouse_filter=2` (pass-through). Buttons are children.

### .tscn Manual Edit Rules (DO NOT manually write .tscn)
- If needed: SubResource BEFORE nodes, Control uses `offset_*` not `position/size`, every node needs `unique_id`, Color needs alpha, ExtResource needs uid
- **Better: always create scenes in Godot editor**

### Naming
- Enemy group: `"enemy"` (used by tower RangeArea and bullet hit detection)
- Tower group: `"tower"` (for placement slot detection)
- Tree class: `GameTree` (not `Tree` — conflicts with Godot built-in Tree UI node)

## Collision Layers
- Layer 1: enemies + towers + bullets
- Layer 2: marked trees (Area2D enabled only when marked)

## Current State
- Trees spawn on grass tiles, grow in 15s, click to mark for tower attack
- Floating text works (金币不足。。) with ColorRect+Label+Tween animation
- Tower upgrade ring: level 1→2 (80g), 2→3 (150g). Sell = 50% of total invested.
- Settings panel: reused in StartScreen and game
- StartScreen is the main scene; clicking 开始游戏 goes to tower_defense.tscn
- Wave config has 2 entries; fallback repeats last entry
- TileMapLayer needs manual grass tile painting for tree spawns

## Pending / Known Issues
- FloatingText.tscn/floating_text.gd files are orphaned (not used, can delete)
- Tile painting still manual (user's preference)
- SFX are programmatic placeholders; BGM uses external mp3
