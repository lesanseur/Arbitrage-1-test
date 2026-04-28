$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonPath = Join-Path $scriptDir ".venv\Scripts\python.exe"
$scriptPath = Join-Path $scriptDir "TEST.py"

if (-not (Test-Path $pythonPath)) {
    throw "Python venv not found at .venv. Ask me to reinstall setup."
}

if (-not (Test-Path $scriptPath)) {
    throw "TEST.py not found."
}

Set-Location $scriptDir
& $pythonPath $scriptPath
