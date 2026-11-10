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
Write-Host (U "  SURFACE JP DOCTOR // B\u1ED8 C\u00D4NG C\u1EE4 CH\u1EA8N \u0110O\u00C1N & FIX B\u00C0N PH\u00CDM NH\u1EACT (JIS)") -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (U "  [*] \u0110ang t\u1EA3i b\u1ED9 c\u00F4ng c\u1EE5 v\u1EC1 C:\surface-jp-doctor ...") -ForegroundColor Gray

$files = @(
    @{ Remote = "$BaseUrl/index.html"; Local = (Join-Path $WorkDir "index.html") },
    @{ Remote = "$BaseUrl/AGENTS.md"; Local = (Join-Path $WorkDir "AGENTS.md") },
    @{ Remote = "$BaseUrl/scripts/diagnose.ps1"; Local = (Join-Path $ScriptsDir "diagnose.ps1") },
    @{ Remote = "$BaseUrl/scripts/fix-layout.ps1"; Local = (Join-Path $ScriptsDir "fix-layout.ps1") }
)

foreach ($f in $files) {
    try {
        $resp = Invoke-WebRequest -Uri $f.Remote -UseBasicParsing
        if ($resp.RawContentStream) {
            $bytes = $resp.Content
            if ($bytes -is [byte[]]) {
                [System.IO.File]::WriteAllBytes($f.Local, $bytes)
            } else {
                [System.IO.File]::WriteAllText($f.Local, [string]$resp.Content, [System.Text.Encoding]::UTF8)
            }
        }
    } catch {}
}

# Run initial diagnosis
& (Join-Path $ScriptsDir "diagnose.ps1")

# Open visual keyboard tester in default browser
$testerHtml = Join-Path $WorkDir "index.html"
if (Test-Path $testerHtml) {
    Write-Host (U "  [*] \u0110ang m\u1EDF B\u1EA3ng Test Ph\u00EDm Tr\u1EF1c Quan (JIS vs US) tr\u00EAn tr\u00ECnh duy\u1EC7t...") -ForegroundColor Yellow
    Start-Process $testerHtml
}

while ($true) {
    Write-Host ""
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host (U "  MENU S\u1EECA L\u1ED6I NHANH C\u1EE4M PH\u00CDM ()= SURFACE N\u1ED8I \u0110\u1ECAA NH\u1EACT:") -ForegroundColor Cyan
    Write-Host (U "  [1] FIX NGAY (Khuy\u00EAn d\u00F9ng - Kh\u00F4ng c\u1EA7n Reboot): Ch\u1EBF \u0111\u1ED9 Lai Th\u00F4ng Minh") -ForegroundColor Green
    Write-Host (U "      -> B\u1EA5m Shift+8 ra '(', Shift+9 (ho\u1EB7c Shift+0) ra ')', Shift+- (ho\u1EB7c n\u00FAt c\u1EA1nh '-') ra '='") -ForegroundColor Gray
    Write-Host (U "  [2] C\u1EE8U PH\u00CDM LI\u1EC6T V\u1EACT L\u00DD (Kh\u00F4ng c\u1EA7n Reboot - D\u00F9ng khi n\u00FAt 8,9,0,- \u0111\u1EE9t m\u1EA1ch):") -ForegroundColor Yellow
    Write-Host (U "      -> G\u00E1n n\u00FAt nh\u1EADt [\u7121\u5909\u63DB/F9]='(', [\u5909\u63DB/F10]=')', [\u30AB\u30BF\u30AB\u30CA/\u00A5/F11]='=', [_ Ro/F12]='-'") -ForegroundColor Gray
    Write-Host (U "  [3] Chuy\u1EC3n Driver Windows sang chu\u1EA9n Nh\u1EADt G\u1ED1c (JIS 106/109 - kbd106.dll)") -ForegroundColor White
    Write-Host (U "  [4] Chuy\u1EC3n Driver Windows sang chu\u1EA9n Qu\u1ED1c T\u1EBF M\u1EF9 (US 101/102 - kbd101.dll)") -ForegroundColor White
    Write-Host (U "  [5] M\u1EDF l\u1EA1i B\u1EA3ng Test Ph\u00EDm (index.html) & Ch\u1EA1y l\u1EA1i Kh\u00E1m S\u1EE9c Kh\u1ECFe M\u00E1y (Pin/SSD)") -ForegroundColor White
    Write-Host (U "  [6] Kh\u00F4i ph\u1EE5c nguy\u00EAn tr\u1EA1ng ban \u0111\u1EA7u (Rollback Registry & t\u1EAFt KeyFixer)") -ForegroundColor Magenta
    Write-Host (U "  [7] C\u00E0i & M\u1EDF Antigravity CLI (agy) ngay t\u1EA1i C:\surface-jp-doctor") -ForegroundColor Cyan
    Write-Host (U "  [0] Tho\u00E1t") -ForegroundColor DarkGray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkCyan
    $choice = Read-Host (U "  Nh\u1EADp l\u1EF1a ch\u1ECDn c\u1EE7a b\u1EA1n (1-7, 0 \u0111\u1EC3 tho\u00E1t)")

    switch ($choice.Trim()) {
        "1" { & (Join-Path $ScriptsDir "fix-layout.ps1") -Mode HybridInstant }
        "2" { & (Join-Path $ScriptsDir "fix-layout.ps1") -Mode DeadKeyRescue }
        "3" { & (Join-Path $ScriptsDir "fix-layout.ps1") -Mode JIS106 }
        "4" { & (Join-Path $ScriptsDir "fix-layout.ps1") -Mode US101 }
        "5" {
            & (Join-Path $ScriptsDir "diagnose.ps1")
            if (Test-Path $testerHtml) { Start-Process $testerHtml }
        }
        "6" { & (Join-Path $ScriptsDir "fix-layout.ps1") -Mode Rollback }
        "7" {
            Invoke-RestMethod "$BaseUrl/agy-go.ps1" | Invoke-Expression
            break
        }
        "0" { break }
        default { Write-Host (U "  [!] Vui l\u00F2ng nh\u1EADp s\u1ED1 t\u1EEB 0 \u0111\u1EBFn 7.") -ForegroundColor Red }
    }
}
