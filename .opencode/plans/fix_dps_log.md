# 修复 DPS 日志 — `OS.execute` 回退方案

## 改动

### 1. `核心/main.gd` — `_ensure_logs_dir()` 加回退

**替换**第 100-103 行：
```gdscript
func _ensure_logs_dir() -> void:
	var ud = OS.get_user_data_dir()
	var logs_abs = ud.path_join("logs")
	var ret = DirAccess.make_dir_recursive_absolute(logs_abs)
	if ret != OK:
		var cmd = "New-Item -ItemType Directory -Path '%s' -Force" % [logs_abs]
		OS.execute("powershell", ["-NoProfile", "-Command", cmd])
```

### 2. `UI/panel_dps_meter.gd` — `dump_to_log()` 加回退

**替换**第 130-132 行：
```gdscript
	var ud = OS.get_user_data_dir()
	var logs_abs = ud.path_join("logs")
	var ret = DirAccess.make_dir_recursive_absolute(logs_abs)
	if ret != OK:
		var cmd = "New-Item -ItemType Directory -Path '%s' -Force" % [logs_abs]
		OS.execute("powershell", ["-NoProfile", "-Command", cmd])
```

## 测试

1. 删掉手动创建的目录（PowerShell）：
   ```
   Remove-Item -Recurse -Force "$env:APPDATA\Roaming\Godot\app_userdata" -ErrorAction SilentlyContinue
   ```
2. 保存文件
3. 重启游戏
4. 按 L
