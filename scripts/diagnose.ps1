param(
    [switch]$JsonOnly,
    [string]$ReportPath = "C:\surface-jp-doctor\surface-report.html"
)

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function U([string]$s) {
    return [regex]::Unescape($s)
}

$WorkDir = "C:\surface-jp-doctor"
if (!(Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# 1. System & Surface Info
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

$model = if ($cs.Model) { $cs.Model.Trim() } else { "Unknown Model" }
$manufacturer = if ($cs.Manufacturer) { $cs.Manufacturer.Trim() } else { "Unknown" }
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$serial = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "N/A" }
$biosVer = if ($bios.SMBIOSBIOSVersion) { $bios.SMBIOSBIOSVersion.Trim() } else { "N/A" }

# 2. Keyboard Driver & Layout Registry Inspection
$i8042Path = "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters"
$i8042 = Get-ItemProperty -Path $i8042Path
$layerDriverJpn = if ($i8042.'LayerDriver JPN') { $i8042.'LayerDriver JPN' } else { "Default" }
$overrideId = if ($i8042.OverrideKeyboardIdentifier) { $i8042.OverrideKeyboardIdentifier } else { "None" }
$overrideType = if ($null -ne $i8042.OverrideKeyboardType) { $i8042.OverrideKeyboardType } else { -1 }
$overrideSubtype = if ($null -ne $i8042.OverrideKeyboardSubtype) { $i8042.OverrideKeyboardSubtype } else { -1 }

$kbdLayoutReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
$hasScancodeMap = ($null -ne $kbdLayoutReg.'Scancode Map')

$langList = Get-WinUserLanguageList
$langs = @()
if ($langList) {
    foreach ($l in $langList) {
        $langs += "$($l.LanguageTag) ($($l.InputMethodTips -join ', '))"
    }
}
$langSummary = if ($langs.Count -gt 0) { $langs -join " | " } else { "Unknown" }

# Determine Keyboard Layout Diagnosis
$isJisDriver = ($layerDriverJpn -match "106") -or ($overrideId -match "106") -or ($overrideSubtype -eq 2)
$layoutVerdict = if ($isJisDriver) {
    "JIS_106 (Driver ban phim dang o chuan Nhat JIS 106/109: Shift+8='(', Shift+9=')', Shift+-='=')"
} else {
    "US_101 (Driver ban phim dang o chuan My US 101/102: Shift+8='*', Shift+9='(', Shift+0=')', Shift+-='_')"
}

$fixerProc = Get-Process -Name "SurfaceKeyFixer" -ErrorAction SilentlyContinue
$isFixerRunning = ($null -ne $fixerProc)

# 3. Battery Health & Cycle Count
$batteryDesign = 0
$batteryFull = 0
$batteryWearPct = -1
$batteryCycles = "N/A"
$batteryStatus = "Unknown"

$batReportXml = Join-Path $env:TEMP "surface_bat_report.xml"
powercfg /batteryreport /xml /output "$batReportXml" | Out-Null
if (Test-Path $batReportXml) {
    try {
        [xml]$bxml = Get-Content $batReportXml -Raw
        $batNode = $bxml.BatteryReport.Batteries.Battery | Select-Object -First 1
        if ($batNode) {
            $batteryDesign = [int64]$batNode.DesignCapacity
            $batteryFull = [int64]$batNode.FullChargeCapacity
            $batteryCycles = [string]$batNode.CycleCount
            if ($batteryDesign -gt 0 -and $batteryFull -gt 0) {
                $ratio = ($batteryFull / $batteryDesign) * 100.0
                $batteryWearPct = [math]::Round(100.0 - $ratio, 1)
                if ($batteryWearPct -lt 0) { $batteryWearPct = 0 }
                $batteryStatus = "$([math]::Round($ratio, 1))% dung luong con lai (Chai $batteryWearPct%, Sac $batteryCycles chu ky)"
            }
        }
    } catch {}
}

# 4. SSD Health
$diskSummary = "Unknown"
try {
    $pd = Get-PhysicalDisk | Select-Object -First 1
    if ($pd) {
        $rel = Get-StorageReliabilityCounter -PhysicalDisk $pd
        $temp = if ($rel -and $rel.Temperature) { "$($rel.Temperature) C" } else { "N/A" }
        $hours = if ($rel -and $rel.PowerOnHours) { "$($rel.PowerOnHours)h" } else { "N/A" }
        $wear = if ($rel -and $null -ne $rel.Wear) { "$($rel.Wear)%" } else { "N/A" }
        $diskSummary = "$($pd.FriendlyName) ($([math]::Round($pd.Size/1GB, 0)) GB) - Health: $($pd.HealthStatus), Temp: $temp, PowerOn: $hours, Wear: $wear"
    }
} catch {}

# 5. Device Manager Error Scan (Keyboard, HID, Surface Firmware)
$problemDevices = @()
try {
    $errDevs = Get-PnpDevice | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
    foreach ($d in $errDevs) {
        $problemDevices += "$($d.Class): $($d.FriendlyName) (Error Code $($d.ConfigManagerErrorCode))"
    }
} catch {}

$kbdDevices = @()
try {
    $kDevs = Get-PnpDevice -Class Keyboard -Status OK
    foreach ($k in $kDevs) {
        $kbdDevices += $k.FriendlyName
    }
} catch {}

$result = [ordered]@{
    Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Model = $model
    Manufacturer = $manufacturer
    Serial = $serial
    BIOS = $biosVer
    CPU = if ($cpu.Name) { $cpu.Name.Trim() } else { "N/A" }
    RAM_GB = $ramGB
    OS = "$($os.Caption) (Build $($os.BuildNumber))"
    Keyboard = [ordered]@{
        LayerDriverJPN = $layerDriverJpn
        OverrideKeyboardIdentifier = $overrideId
        OverrideKeyboardType = $overrideType
        OverrideKeyboardSubtype = $overrideSubtype
        HasScancodeMap = $hasScancodeMap
        SurfaceKeyFixerActive = $isFixerRunning
        Languages = $langSummary
        ActiveKeyboards = ($kbdDevices -join ", ")
        Verdict = $layoutVerdict
    }
    Battery = [ordered]@{
        DesignCapacity_mWh = $batteryDesign
        FullChargeCapacity_mWh = $batteryFull
        CycleCount = $batteryCycles
        WearPercent = $batteryWearPct
        Summary = $batteryStatus
    }
    Storage = $diskSummary
    DeviceErrors = $problemDevices
}

$jsonOut = $result | ConvertTo-Json -Depth 5
$jsonFile = Join-Path $WorkDir "diagnosis.json"
[System.IO.File]::WriteAllText($jsonFile, $jsonOut, [System.Text.Encoding]::UTF8)

if ($JsonOnly) {
    Write-Output $jsonOut
    exit 0
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (U "  SURFACE JP DOCTOR // B\u00C1O C\u00C1O CH\u1EA8N \u0110O\u00C1N NHANH") -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host (U "  M\u00E1y         : ") -NoNewline -ForegroundColor Gray; Write-Host "$model ($manufacturer) - Serial: $serial" -ForegroundColor White
Write-Host (U "  C\u1EA5u h\u00ECnh    : ") -NoNewline -ForegroundColor Gray; Write-Host "$($result.CPU) | RAM $ramGB GB | UEFI $biosVer" -ForegroundColor White
Write-Host (U "  Pin Surface : ") -NoNewline -ForegroundColor Gray; Write-Host "$batteryStatus ($batteryFull / $batteryDesign mWh)" -ForegroundColor Yellow
Write-Host (U "  \u1ED4 c\u1EE9ng SSD  : ") -NoNewline -ForegroundColor Gray; Write-Host "$diskSummary" -ForegroundColor White
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host (U "  [CH\u1EA8N \u0110O\u00C1N B\u00C0N PH\u00CDM N\u1ED8I \u0110\u1ECAA NH\u1EACT - C\u1EE4M PH\u00CDM ()=]") -ForegroundColor Green
Write-Host (U "  Driver Registry : ") -NoNewline -ForegroundColor Gray; Write-Host "LayerDriver JPN = $layerDriverJpn | Override = $overrideId (SubType: $overrideSubtype)" -ForegroundColor White
Write-Host (U "  Ng\u00F4n ng\u1EEF Windows: ") -NoNewline -ForegroundColor Gray; Write-Host "$langSummary" -ForegroundColor White
Write-Host (U "  KeyFixer Ng\u1EA7m   : ") -NoNewline -ForegroundColor Gray; Write-Host ($(if ($isFixerRunning) { "DANG CHAY (Active)" } else { "Chua bat" })) -ForegroundColor ($(if ($isFixerRunning) { "Green" } else { "DarkYellow" }))
Write-Host (U "  Scancode Map    : ") -NoNewline -ForegroundColor Gray; Write-Host ($(if ($hasScancodeMap) { "Co remap trong Registry" } else { "Mac dinh (Chua remap)" })) -ForegroundColor White
Write-Host (U "  K\u1EBFt lu\u1EADn Layout : ") -NoNewline -ForegroundColor Gray; Write-Host "$layoutVerdict" -ForegroundColor Cyan

if ($problemDevices.Count -gt 0) {
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host (U "  [!] PH\u00C1T HI\u1EC6N THI\u1EBET B\u1ECA B\u00C1O L\u1ED6I TRONG DEVICE MANAGER:") -ForegroundColor Red
    foreach ($err in $problemDevices) {
        Write-Host "      - $err" -ForegroundColor Red
    }
} else {
    Write-Host (U "  Driver Thi\u1EBFt b\u1ECB : ") -NoNewline -ForegroundColor Gray; Write-Host (U "100% OK (Kh\u00F4ng c\u00F3 thi\u1EBFt b\u1ECB b\u00E1o ch\u1EA5m than v\u00E0ng)") -ForegroundColor Green
}
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
