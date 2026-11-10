$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function U([string]$s) {
    return [regex]::Unescape($s)
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host (U "  SURFACE JP DOCTOR // D\u1ECDN S\u1EA0CH PHI\u00CAN \u0110\u0102NG NH\u1EACP ANTIGRAVITY CLI") -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

# 1. Clear Windows Credential Manager entries related to Antigravity / Gemini
$credList = cmdkey /list
foreach ($line in $credList) {
    if ($line -match "Target:\s*(.*(antigravity|agy|gemini|google).*)") {
        $target = $Matches[1].Trim()
        cmdkey /delete:$target | Out-Null
        Write-Host (U "  [+] \u0110\u00E3 xo\u00E1 Credential: $target") -ForegroundColor Yellow
    }
}

# 2. Remove ~/.gemini and %LOCALAPPDATA%\agy
$geminiDir = Join-Path $env:USERPROFILE ".gemini"
$agyLocalDir = Join-Path $env:LOCALAPPDATA "agy"
$agyAppDataDir = Join-Path $env:APPDATA "agy"

foreach ($dir in @($geminiDir, $agyLocalDir, $agyAppDataDir)) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host (U "  [+] \u0110\u00E3 xo\u00E1 th\u01B0 m\u1EE5c token/CLI: $dir") -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host (U "  [OK] \u0110\u00C3 XO\u00C1 S\u1EA0CH 100% T\u00C0I KHO\u1EA2N & SESSION AGY TR\u00CAN M\u00C1Y N\u00C0Y!") -ForegroundColor Green
Write-Host (U "  [OK] B\u1ED9 fix b\u00E0n ph\u00EDm Surface (C:\surface-jp-doctor\bin\SurfaceKeyFixer.exe) v\u1EABn gi\u1EEF nguy\u00EAn ho\u1EA1t \u0111\u1ED9ng b\u00ECnh th\u01B0\u1EDDng.") -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host ""
