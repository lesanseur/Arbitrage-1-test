$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "stop.ps1")
Start-Sleep -Seconds 1
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "start-bg.ps1")
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "status.ps1")
