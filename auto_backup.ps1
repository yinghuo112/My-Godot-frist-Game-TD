# ========================================
# 自动提交脚本（PowerShell版）
# 功能：检测本地仓库变更，自动提交并推送
# 用法：右键 -> 使用 PowerShell 运行，或添加到任务计划程序
# ========================================

# ---------- 配置区（请修改为你的实际路径）----------
$RepoPath = "D:\Administrator\Game\first-游戏"
# ---------- 配置结束 ----------

# 切换到仓库目录
Set-Location -Path $RepoPath -ErrorAction Stop

# 检查是否为 git 仓库
try {
    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) { throw "不是 git 仓库" }
}
catch {
    Write-Host "[错误] 当前目录不是 git 仓库: $RepoPath" -ForegroundColor Red
    exit 1
}

# 检查是否有未提交的更改
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "[信息] 没有变更，退出。"
    exit 0
}

# 获取当前时间
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMsg = "自动备份 $timestamp"

# 添加所有变更
Write-Host "[信息] 检测到变更，准备提交..." -ForegroundColor Yellow
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] git add 失败" -ForegroundColor Red
    exit 1
}

# 提交
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] git commit 失败" -ForegroundColor Red
    exit 1
}

# 推送到远程（先尝试拉取最新，避免冲突）
Write-Host "[信息] 正在拉取远程更新..." -ForegroundColor Yellow
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[警告] git pull 失败，跳过拉取，直接推送" -ForegroundColor Yellow
}

Write-Host "[信息] 正在推送到远程仓库..." -ForegroundColor Yellow
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] git push 失败，请检查网络或认证" -ForegroundColor Red
    exit 1
}

Write-Host "[成功] 已提交并推送: $commitMsg" -ForegroundColor Green
exit 0
