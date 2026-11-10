$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function U([string]$s) {
    return [regex]::Unescape($s)
}

$WorkDir = "C:\surface-jp-doctor"
$ScriptsDir = Join-Path $WorkDir "scripts"
New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null

$BaseUrl = "https://raw.githubusercontent.com/tsennguyen/surface-jp-doctor/main"

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (U "  SURFACE JP DOCTOR // AUTO-SETUP ANTIGRAVITY CLI (agy)") -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Download repo files into C:\surface-jp-doctor (Zero Git dependency)
Write-Host (U "  [1/3] \u0110ang t\u1EA3i repo surface-jp-doctor v\u1EC1 C:\surface-jp-doctor ...") -ForegroundColor Yellow
$files = @(
    @{ Remote = "$BaseUrl/index.html"; Local = (Join-Path $WorkDir "index.html") },
    @{ Remote = "$BaseUrl/AGENTS.md"; Local = (Join-Path $WorkDir "AGENTS.md") },
    @{ Remote = "$BaseUrl/README.md"; Local = (Join-Path $WorkDir "README.md") },
    @{ Remote = "$BaseUrl/run.ps1"; Local = (Join-Path $WorkDir "run.ps1") },
    @{ Remote = "$BaseUrl/agy-clean.ps1"; Local = (Join-Path $WorkDir "agy-clean.ps1") },
    @{ Remote = "$BaseUrl/scripts/diagnose.ps1"; Local = (Join-Path $ScriptsDir "diagnose.ps1") },
    @{ Remote = "$BaseUrl/scripts/fix-layout.ps1"; Local = (Join-Path $ScriptsDir "fix-layout.ps1") }
)

foreach ($f in $files) {
    try {
        $resp = Invoke-WebRequest -Uri $f.Remote -UseBasicParsing
        if ($resp.Content) {
            [System.IO.File]::WriteAllText($f.Local, [string]$resp.Content, [System.Text.Encoding]::UTF8)
        }
    } catch {}
}

# 2. Check & Install Antigravity CLI (agy)
$agyBinDir = Join-Path $env:LOCALAPPDATA "agy\bin"
if ($env:Path -notlike "*$agyBinDir*") {
    $env:Path = "$agyBinDir;$env:Path"
}

$agyCmd = Get-Command agy -ErrorAction SilentlyContinue
if (!$agyCmd) {
    Write-Host (U "  [2/3] \u0110ang c\u00E0i \u0111\u1EB7t Antigravity CLI (agy) ch\u00EDnh ch\u1EE7 Google...") -ForegroundColor Yellow
    Invoke-RestMethod "https://antigravity.google/cli/install.ps1" | Invoke-Expression
    if (Test-Path (Join-Path $agyBinDir "agy.exe")) {
        $env:Path = "$agyBinDir;$env:Path"
    }
} else {
    Write-Host (U "  [2/3] \u0110\u00E3 c\u00F3 s\u1EB5n Antigravity CLI (agy)!") -ForegroundColor Green
}

# 3. Copy starter prompt to Windows Clipboard & Launch agy
$promptText = U "\u0110\u1ECDc AGENTS.md trong th\u01B0 m\u1EE5c hi\u1EC7n t\u1EA1i (C:\surface-jp-doctor), ch\u1EA1y ngay scripts\diagnose.ps1 v\u00E0 m\u1EDF index.html \u0111\u1EC3 ki\u1EC3m tra l\u1ED7i c\u1EE5m ph\u00EDm ()= tr\u00EAn m\u00E1y Surface n\u1ED9i \u0111\u1ECBa Nh\u1EADt n\u00E0y, sau \u0111\u00F3 fix ngay (ch\u1EBF \u0111\u1ED9 HybridInstant ho\u1EB7c DeadKeyRescue tu\u1EF3 k\u1EBFt qu\u1EA3 test) v\u00E0 b\u00E1o c\u00E1o t\u00ECnh tr\u1EA1ng Pin/SSD/Driver b\u1EB1ng ti\u1EBFng Vi\u1EC7t ng\u1EAFn g\u1ECDn."
try {
    Set-Clipboard -Value $promptText
    Write-Host (U "  [3/3] \u0110\u00E3 copy s\u1EB5n c\u00E2u Prompt v\u00E0o Clipboard! Khi v\u00E0o agy, ch\u1EC9 c\u1EA7n b\u1EA5m Ctrl+V -> Enter (ho\u1EB7c g\u00F5: kham)!") -ForegroundColor Green
} catch {}

Write-Host "==================================================================" -ForegroundColor Cyan
Set-Location $WorkDir
& agy
