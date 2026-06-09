# ========================================
# auto backup script (PowerShell)
# detect changes -> commit -> push if remote exists
# Usage: .\auto_backup.ps1              one-shot
#        .\auto_backup.ps1 -Daemon      loop every 30min
#        Windows Task Scheduler          timer trigger
# ========================================

param([switch]$Daemon)

$RepoPath = "D:\Administrator\Game\first-游戏"
$LogDir  = Join-Path $RepoPath "Log"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Run-Backup {
    $logFile = Join-Path $LogDir ("backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
    function L { param([string]$m) $m | Out-File -FilePath $logFile -Append }

    Set-Location $RepoPath
    L ("=" * 40)
    L ("start: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))

    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) { L "[ERR] not a git repo"; return }

    $changes = git status --porcelain
    if (-not $changes) { L "[OK] no changes"; return }

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "auto backup $ts"
    L "[INFO] changes detected, committing..."

    git add .
    if ($LASTEXITCODE -ne 0) { L "[ERR] git add failed"; return }

    git commit -m $msg
    if ($LASTEXITCODE -ne 0) { L "[ERR] git commit failed"; return }

    $pushOk = $false
    $hasRemote = git remote -v
    if ($hasRemote) {
        $branch = git branch --show-current
        L "[INFO] pushing to origin/$branch ..."
        git pull --rebase origin $branch 2>&1 | Out-Null
        git push origin $branch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { L "[OK] pushed"; $pushOk = $true }
        else { L "[WARN] push failed (network?)" }
    } else {
        L "[INFO] no remote, local commit only"
    }
    L "[DONE] $msg"

    # 弹窗通知
    $pop = New-Object -ComObject WScript.Shell
    if ($pushOk) {
        $pop.Popup("Backup pushed to GitHub: $ts", 5, "Auto Backup", 64)
    } else {
        $pop.Popup("Backup committed (local): $ts", 5, "Auto Backup", 64)
    }
}

if ($Daemon) {
    while ($true) {
        Run-Backup
        Start-Sleep -Seconds 1800
    }
} else {
    Run-Backup
}