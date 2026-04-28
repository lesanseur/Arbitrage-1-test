$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonPath = Join-Path $scriptDir ".venv\Scripts\python.exe"
$scriptPath = Join-Path $scriptDir "TEST.py"
$runDir = Join-Path $scriptDir "run"
$pidPath = Join-Path $runDir "bot.pid"
$outLog = Join-Path $runDir "stdout.log"
$errLog = Join-Path $runDir "stderr.log"
$archiveDir = Join-Path $runDir "archive"

if (-not (Test-Path $pythonPath)) {
    throw "Python venv not found at .venv."
}

if (-not (Test-Path $scriptPath)) {
    throw "TEST.py not found."
}

if (-not (Test-Path $runDir)) {
    New-Item -Path $runDir -ItemType Directory | Out-Null
}
if (-not (Test-Path $archiveDir)) {
    New-Item -Path $archiveDir -ItemType Directory | Out-Null
}

# Rotate logs if existing file exceeds 5 MB.
$maxBytes = 5MB
if (Test-Path $outLog) {
    $outInfo = Get-Item $outLog
    if ($outInfo.Length -gt $maxBytes) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Move-Item $outLog (Join-Path $archiveDir "stdout-$stamp.log") -Force
    }
}
if (Test-Path $errLog) {
    $errInfo = Get-Item $errLog
    if ($errInfo.Length -gt $maxBytes) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Move-Item $errLog (Join-Path $archiveDir "stderr-$stamp.log") -Force
    }
}

if (Test-Path $pidPath) {
    $existingPid = (Get-Content $pidPath -Raw).Trim()
    if ($existingPid) {
        try {
            $runningProc = Get-Process -Id ([int]$existingPid) -ErrorAction Stop
            Write-Host "Bot already running (PID=$($runningProc.Id))."
            exit 0
        } catch {
            Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
        }
    }
}

$args = @("-u", "`"$scriptPath`"")
$proc = Start-Process -FilePath $pythonPath `
    -ArgumentList $args `
    -WorkingDirectory $scriptDir `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -PassThru

Set-Content -Path $pidPath -Value $proc.Id

Write-Host "Bot started in background."
Write-Host "PID: $($proc.Id)"
Write-Host "stdout: $outLog"
Write-Host "stderr: $errLog"
