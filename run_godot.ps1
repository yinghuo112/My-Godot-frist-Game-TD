# Godot launch script - auto pipe output to Log/
param([string]$Mode = "editor")

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $ProjectDir "Log"

# Ensure Log dir exists
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# Locate Godot executable
$PathsToTry = @(
    "$env:LOCALAPPDATA\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe",
    "D:\Administrator\Downloads\Apps\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe",
    "$env:LOCALAPPDATA\Godot\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe",
    "D:\Administrator\Downloads\Apps\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe",
    "D:\Administrator\Downloads\Apps\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
)
$Exe = $null
foreach ($p in $PathsToTry) {
    if (Test-Path $p) { $Exe = $p; break }
}
if (-not $Exe) { Write-Host "[ERR] Godot executable not found" -ForegroundColor Red; exit 1 }

# Build arguments
$ArgsList = @("--path", "`"$ProjectDir`"")
switch -Wildcard ($Mode) {
    "run"       { $ArgsList += "--headless", "--quit", "--wait-for-signal"; $Suffix = "run" }
    "scene=*"   { $ArgsList += $Mode.Substring(6); $Suffix = "scene" }
    default     { $Suffix = "editor" }
}
$LogFile = "Log/godot_${Suffix}_${Timestamp}.log"
$LogPath = Join-Path $ProjectDir $LogFile

Write-Host "Godot: $Exe" -ForegroundColor Cyan
Write-Host "Mode:  $Mode" -ForegroundColor Cyan
Write-Host "Log:   $LogPath" -ForegroundColor Cyan

# Launch + redirect stdout/stderr
& $Exe $ArgsList *> $LogPath