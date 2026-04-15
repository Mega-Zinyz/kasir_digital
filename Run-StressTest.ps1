# Run-StressTest.ps1
# ============================================================
# Script runner untuk stress & load test - kasir_digital
# Jalankan dari root folder proyek:
#   .\Run-StressTest.ps1
# Atau dengan opsi:
#   .\Run-StressTest.ps1 -Test all -Verbose
# ============================================================

param(
    [ValidateSet('all', 'database', 'provider')]
    [string]$Test = 'all',

    [int]$TimeoutSeconds = 120,

    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

# ── Warna & output helpers ───────────────────────────────────────────────────
function Write-Header {
    param([string]$Text)
    $line = '=' * 70
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "$line" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n>>  $Text" -ForegroundColor Yellow
}

function Write-OK   { param([string]$Text); Write-Host "  [OK]  $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text); Write-Host "  [!!]  $Text" -ForegroundColor Magenta }
function Write-Fail { param([string]$Text); Write-Host "  [XX]  $Text" -ForegroundColor Red }

# ── Pastikan di dalam folder proyek Flutter ──────────────────────────────────
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

if (-not (Test-Path 'pubspec.yaml')) {
    Write-Fail "Tidak ditemukan pubspec.yaml. Jalankan script dari root folder proyek Flutter."
    exit 1
}

$appName = (Select-String -Path 'pubspec.yaml' -Pattern '^name:\s*(.+)').Matches[0].Groups[1].Value.Trim()

Write-Header "Stress + Load Test Runner - $appName"
Write-Host "  Waktu  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "  Mode   : $Test"
Write-Host "  Timeout: $TimeoutSeconds detik per suite"
Write-Host ""

# ── Cek flutter tersedia ─────────────────────────────────────────────────────
Write-Step "Memeriksa Flutter SDK..."
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-OK $flutterVersion
} catch {
    Write-Fail "Flutter tidak ditemukan di PATH. Install Flutter dan coba lagi."
    exit 1
}
if ($LASTEXITCODE -eq $null -or (($flutterVersion -join '') -notmatch 'Flutter')) {
    Write-Fail "Flutter tidak ditemukan di PATH. Install Flutter dan coba lagi."
    exit 1
}

# ── flutter pub get ──────────────────────────────────────────────────────────
Write-Step "Memperbarui dependensi (flutter pub get)..."
$pubResult = flutter pub get 2>&1
# Anggap sukses jika output mengandung marker sukses (warning file_picker bukan kegagalan)
$pubOutput = $pubResult | Out-String
$pubSuccess = ($pubOutput -match 'Got dependencies|No dependencies changed')
if (-not $pubSuccess) {
    Write-Fail "flutter pub get gagal. Output:`n$pubOutput"
    exit 1
}
Write-OK "Dependensi berhasil diperbarui."

# ── Definisi suite ────────────────────────────────────────────────────────────
$suites = @()

if ($Test -eq 'all' -or $Test -eq 'database') {
    $suites += [PSCustomObject]@{
        Name    = 'Database Stress Test'
        File    = 'test/stress/database_stress_test.dart'
        Timeout = $TimeoutSeconds
    }
}

if ($Test -eq 'all' -or $Test -eq 'provider') {
    $suites += [PSCustomObject]@{
        Name    = 'Provider Load Test'
        File    = 'test/stress/provider_load_test.dart'
        Timeout = $TimeoutSeconds
    }
}

# ── Jalankan setiap suite ────────────────────────────────────────────────────
$globalStart  = Get-Date
$passedSuites = 0
$failedSuites = 0
$suiteReports = @()

foreach ($suite in $suites) {
    Write-Header $suite.Name
    Write-Host "  File   : $($suite.File)"
    Write-Host "  Timeout: $($suite.Timeout)s`n"

    if (-not (Test-Path $suite.File)) {
        Write-Fail "File test tidak ditemukan: $($suite.File)"
        $failedSuites++
        $suiteReports += [PSCustomObject]@{
            Suite   = $suite.Name
            Status  = 'NOT FOUND'
            DurationS = 0
            Output  = 'File tidak ditemukan'
        }
        continue
    }

    $suiteStart = Get-Date

    # Perintah flutter test
    $flutterArgs = @(
        'test',
        $suite.File,
        "--timeout=$($suite.Timeout)s",
        '--reporter=expanded'
    )

    if ($Verbose) {
        Write-Host "  CMD: flutter $($flutterArgs -join ' ')" -ForegroundColor DarkGray
    }

    # Jalankan dan tangkap output
    $output = & flutter @flutterArgs 2>&1
    $exitCode = $LASTEXITCODE

    $suiteDuration = [int]((Get-Date) - $suiteStart).TotalSeconds

    if ($exitCode -eq 0) {
        Write-OK "Suite LULUS dalam $suiteDuration detik."
        $passedSuites++
        $suiteReports += [PSCustomObject]@{
            Suite     = $suite.Name
            Status    = 'PASS'
            DurationS = $suiteDuration
            Output    = ($output -join "`n")
        }
    } else {
        Write-Fail "Suite GAGAL dalam $suiteDuration detik (exit code: $exitCode)."
        $failedSuites++
        $suiteReports += [PSCustomObject]@{
            Suite     = $suite.Name
            Status    = 'FAIL'
            DurationS = $suiteDuration
            Output    = ($output -join "`n")
        }
    }

    # Tampilkan output (selalu tampil untuk stress test agar terlihat hasil metrics)
    Write-Host ""
    $output | Where-Object { $_ -notmatch 'file_picker|RemoteException|default_package|pluginClass|dartPluginClass' } |
        ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

# ── Ringkasan Akhir ──────────────────────────────────────────────────────────
$totalDuration = [int]((Get-Date) - $globalStart).TotalSeconds

Write-Header "RINGKASAN HASIL STRESS & LOAD TEST"

foreach ($report in $suiteReports) {
    $color = switch ($report.Status) {
        'PASS'      { 'Green' }
        'FAIL'      { 'Red' }
        default     { 'Magenta' }
    }
    $icon = switch ($report.Status) {
        'PASS'      { '[OK]' }
        'FAIL'      { '[XX]' }
        default     { '[??]' }
    }
    Write-Host "  $icon [$($report.Status.PadRight(9))] $($report.Suite) - $($report.DurationS)s" -ForegroundColor $color
}

Write-Host ""
Write-Host "  Suite lulus  : $passedSuites / $($suites.Count)" -ForegroundColor $(if ($failedSuites -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "  Suite gagal  : $failedSuites / $($suites.Count)" -ForegroundColor $(if ($failedSuites -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Total waktu  : $totalDuration detik"
Write-Host "  Selesai pada : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ── Simpan laporan ke file ──────────────────────────────────────────────────
$reportDir  = 'build/reports/stress'
$reportFile = "$reportDir/stress_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$reportContent = @"
============================================================
STRESS + LOAD TEST REPORT - $appName
============================================================
Waktu    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode     : $Test
Platform : Windows / Flutter Test Runner

HASIL SUITE:
"@

foreach ($report in $suiteReports) {
    $reportContent += "`n`n[$($report.Status)] $($report.Suite) - $($report.DurationS)s"
    $reportContent += "`n$('-' * 60)"
    $reportContent += "`n$($report.Output)"
}

$reportContent += @"

============================================================
RINGKASAN
  Suite lulus  : $passedSuites / $($suites.Count)
  Suite gagal  : $failedSuites / $($suites.Count)
  Total waktu  : $totalDuration detik
============================================================
"@

$reportContent | Out-File -FilePath $reportFile -Encoding UTF8
Write-OK "Laporan disimpan ke: $reportFile"

# ── Exit code ───────────────────────────────────────────────────────────────
if ($failedSuites -gt 0) {
    Write-Fail "`nAda suite yang gagal. Periksa output di atas."
    exit 1
} else {
    Write-OK "`nSemua suite lulus."
    exit 0
}
