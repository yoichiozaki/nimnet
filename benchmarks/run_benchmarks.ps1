# Run isolated benchmarks against the same generated fixture files.
[CmdletBinding()]
param(
    [switch]$SkipNetworkX,
    [switch]$Micro,
    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed with exit code $LASTEXITCODE"
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $ScriptDir "results"
$Utf8 = [System.Text.UTF8Encoding]::new($false)
$prefix = if ($Micro) { "micro_" } else { "" }
$benchmark = if ($Micro) { "bench_micro" } else { "bench_nimnet" }
$pythonBenchmark = if ($Micro) { "bench_micro_networkx.py" } else { "bench_networkx.py" }
$suite = if ($Micro) { "micro" } else { "main" }
$nimCsv = Join-Path $ResultsDir "${prefix}nimnet.csv"
$nxCsv = Join-Path $ResultsDir "${prefix}networkx.csv"
$combinedCsv = Join-Path $ResultsDir "${prefix}combined.csv"
$metadataPath = Join-Path $ResultsDir "${prefix}metadata.json"

New-Item -ItemType Directory -Force -Path $ResultsDir, "$RootDir\build" | Out-Null
foreach ($name in @("nimnet.csv", "networkx.csv", "combined.csv", "metadata.json")) {
    $path = Join-Path $ResultsDir "${prefix}${name}"
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}
if (-not $SkipNetworkX) {
    Invoke-Checked -Program $Python -Arguments @("-c", "import networkx, numpy, scipy")
}
Invoke-Checked -Program $Python -Arguments @("$ScriptDir\fixtures.py")

Write-Host "=== Building nimnet benchmark (release mode) ===" -ForegroundColor Cyan
Invoke-Checked -Program "nim" -Arguments @(
    "c", "--threads:on", "--hints:off", "-d:release", "--opt:speed",
    "-p:$RootDir\src", "--nimcache:$RootDir\build\nimcache\$benchmark",
    "-o:$RootDir\build\$benchmark.exe", "$ScriptDir\$benchmark.nim"
)

Write-Host "=== Running nimnet benchmarks ===" -ForegroundColor Cyan
$nimOutput = @(Invoke-Checked -Program "$RootDir\build\$benchmark.exe" -Arguments @())
[System.IO.File]::WriteAllLines($nimCsv, [string[]]$nimOutput, $Utf8)
$nimOutput | ForEach-Object { Write-Host $_ }
$inputs = @($nimCsv)
$metadataArgs = @("$ScriptDir\fixtures.py", "--metadata", $metadataPath, "--suite", $suite)

if (-not $SkipNetworkX) {
    Write-Host "=== Running NetworkX benchmarks ===" -ForegroundColor Cyan
    $nxOutput = @(Invoke-Checked -Program $Python -Arguments @("$ScriptDir\$pythonBenchmark"))
    [System.IO.File]::WriteAllLines($nxCsv, [string[]]$nxOutput, $Utf8)
    $nxOutput | ForEach-Object { Write-Host $_ }
    $inputs += $nxCsv
    $metadataArgs += "--include-networkx"
} else {
    Write-Host "NetworkX explicitly skipped (-SkipNetworkX)." -ForegroundColor Yellow
}

Invoke-Checked -Program $Python -Arguments $metadataArgs
Invoke-Checked -Program $Python -Arguments (@(
    "$ScriptDir\compare_results.py", "--output", $combinedCsv, "--suite", $suite
) + $inputs)

Write-Host "Results written to $combinedCsv"
Import-Csv $combinedCsv | Format-Table -AutoSize
