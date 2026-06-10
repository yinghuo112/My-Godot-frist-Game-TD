# Naming Convention
`类型_功能` — type prefix first, function second.
Examples: panel_start.tscn, panel_settings.gd, tower_arrow.tscn, bullet_fireball.gd

# Project Rules
- Language: English code naming, Chinese comments
- Godot 4.6.3: no @export_tooltip, no nested Array[Type] generics
- Color() must have 4 channels in .tres/.tscn
- extends first line, class_name second line
- Do NOT shadow base class properties (use sfx_name/font_name instead of name)
- project.godot has BOM line at line 11 — edit with Python or editor, not Set-Content
- Log files use user:// not res:// to avoid engine loop
- Commit message follows repo style
