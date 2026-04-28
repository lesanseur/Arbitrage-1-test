$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidPath = Join-Path $scriptDir "run\bot.pid"

if (-not (Test-Path $pidPath)) {
    Write-Host "Bot already stopped."
    exit 0
}

$pidValue = (Get-Content $pidPath -Raw).Trim()
if (-not $pidValue) {
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
    Write-Host "Invalid PID file removed."
    exit 0
}

try {
    $proc = Get-Process -Id ([int]$pidValue) -ErrorAction Stop
    Stop-Process -Id $proc.Id -Force
    Write-Host "Bot stopped (PID=$($proc.Id))."
} catch {
    Write-Host "Process not found (PID=$pidValue)."
}

Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
