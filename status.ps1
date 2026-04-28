$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidPath = Join-Path $scriptDir "run\bot.pid"
$outLog = Join-Path $scriptDir "run\stdout.log"
$errLog = Join-Path $scriptDir "run\stderr.log"

if (-not (Test-Path $pidPath)) {
    Write-Host "Status: STOPPED"
} else {
    $pidValue = (Get-Content $pidPath -Raw).Trim()
    if ($pidValue) {
        try {
            $proc = Get-Process -Id ([int]$pidValue) -ErrorAction Stop
            Write-Host "Status: RUNNING"
            Write-Host "PID: $($proc.Id)"
            Write-Host "Started: $($proc.StartTime)"
        } catch {
            Write-Host "Status: STALE PID ($pidValue)"
        }
    } else {
        Write-Host "Status: INVALID PID FILE"
    }
}

if (Test-Path $outLog) { Write-Host "stdout: $outLog" }
if (Test-Path $errLog) { Write-Host "stderr: $errLog" }
