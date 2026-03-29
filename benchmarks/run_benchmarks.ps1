# Run nimnet and NetworkX benchmarks on Windows, merge results.
#
# Usage:
#   cd nimnet/
#   pwsh benchmarks/run_benchmarks.ps1
#
# Prerequisites:
#   - Nim compiler (nim, nimble)
#   - Python 3 with networkx (optional):  pip install networkx

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $ScriptDir "results"

if (-not (Test-Path $ResultsDir)) { New-Item -ItemType Directory -Path $ResultsDir | Out-Null }

Write-Host "=== Building nimnet benchmark (release mode) ===" -ForegroundColor Cyan
nim c -d:release -d:danger --opt:speed "-p:$RootDir\src" `
  "--nimcache:$RootDir\build\nimcache\bench" `
  "-o:$RootDir\build\bench_nimnet.exe" `
  "$ScriptDir\bench_nimnet.nim"

Write-Host ""
Write-Host "=== Running nimnet benchmarks ===" -ForegroundColor Cyan
& "$RootDir\build\bench_nimnet.exe" | Tee-Object -FilePath "$ResultsDir\nimnet.csv"

Write-Host ""

# NetworkX (optional)
$pythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    try { python -c "import networkx" 2>$null; $pythonCmd = "python" } catch {}
}
if (-not $pythonCmd -and (Get-Command python3 -ErrorAction SilentlyContinue)) {
    try { python3 -c "import networkx" 2>$null; $pythonCmd = "python3" } catch {}
}

if ($pythonCmd) {
    Write-Host "=== Running NetworkX benchmarks ===" -ForegroundColor Cyan
    & $pythonCmd "$ScriptDir\bench_networkx.py" | Tee-Object -FilePath "$ResultsDir\networkx.csv"
} else {
    Write-Host "Skipping NetworkX benchmarks (python/networkx not found)" -ForegroundColor Yellow
}

# Merge results
Write-Host ""
Write-Host "=== Merging results ===" -ForegroundColor Cyan
$header = "library,benchmark,size,nodes,edges,time_seconds"
$lines = @($header)
foreach ($f in @("$ResultsDir\nimnet.csv", "$ResultsDir\networkx.csv")) {
    if (Test-Path $f) {
        $content = Get-Content $f | Select-Object -Skip 1
        $lines += $content
    }
}
$lines | Set-Content "$ResultsDir\combined.csv"

Write-Host "Results written to $ResultsDir\combined.csv"
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Import-Csv "$ResultsDir\combined.csv" | Format-Table -AutoSize
