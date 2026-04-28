$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvPath = Join-Path $scriptDir "arbitrage_log.csv"

if (-not (Test-Path $csvPath)) {
    Write-Host "No CSV found: $csvPath"
    exit 0
}

$rows = Import-Csv -Path $csvPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "CSV exists but has no data rows."
    exit 0
}

$count = $rows.Count
$avgNet = ($rows | Measure-Object -Property net_spread_pct -Average).Average
$maxNet = ($rows | Measure-Object -Property net_spread_pct -Maximum).Maximum
$minNet = ($rows | Measure-Object -Property net_spread_pct -Minimum).Minimum

$bySignal = $rows | Group-Object -Property signal | Sort-Object Count -Descending

Write-Host "=== Arbitrage Report ==="
Write-Host "Rows: $count"
Write-Host ("Avg net spread: {0:N4}%" -f [double]$avgNet)
Write-Host ("Max net spread: {0:N4}%" -f [double]$maxNet)
Write-Host ("Min net spread: {0:N4}%" -f [double]$minNet)
Write-Host ""
Write-Host "Signals:"
foreach ($g in $bySignal) {
    Write-Host ("- {0} : {1}" -f $g.Name, $g.Count)
}
