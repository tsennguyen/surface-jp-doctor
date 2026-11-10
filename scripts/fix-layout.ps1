param(
    [ValidateSet("HybridInstant", "DeadKeyRescue", "JIS106", "US101", "Rollback")]
    [string]$Mode = "HybridInstant"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function U([string]$s) {
    return [regex]::Unescape($s)
}

$WorkDir = "C:\surface-jp-doctor"
$BinDir = Join-Path $WorkDir "bin"
$BackupDir = Join-Path $WorkDir "backups"
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

function Backup-KeyboardRegistry {
    $regBackupFile = Join-Path $BackupDir "i8042prt-initial.reg"
    if (!(Test-Path $regBackupFile)) {
        reg export "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "$regBackupFile" /y | Out-Null
        Write-Host (U "  [+] \u0110\u00E3 sao l\u01B0u Registry g\u1ED1c t\u1EA1i: $regBackupFile") -ForegroundColor DarkGray
    }
}

function Stop-KeyFixer {
    $procs = Get-Process -Name "SurfaceKeyFixer" -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
    }
}

function Build-And-Start-KeyFixer([string]$FixerMode) {
    Stop-KeyFixer

    $exePath = Join-Path $BinDir "SurfaceKeyFixer.exe"
    $csPath = Join-Path $BinDir "SurfaceKeyFixer.cs"

    $csCode = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace SurfaceJPDoctor
{
    static class Program
    {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const uint LLKHF_INJECTED = 0x00000010;
        private const int INPUT_KEYBOARD = 1;
        private const uint KEYEVENTF_UNICODE = 0x0004;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const int VK_SHIFT = 0x10;
        private const int VK_CONTROL = 0x11;
        private const int VK_MENU = 0x12;

        private static IntPtr _hookID = IntPtr.Zero;
        private static LowLevelKeyboardProc _proc = HookCallback;
        private static string _mode = "jis-legend";

        [STAThread]
        static void Main(string[] args)
        {
            if (args.Length > 0 && !string.IsNullOrEmpty(args[0]))
            {
                _mode = args[0].ToLowerInvariant();
            }
            _hookID = SetHook(_proc);
            Application.Run();
            UnhookWindowsHookEx(_hookID);
        }

        private static IntPtr SetHook(LowLevelKeyboardProc proc)
        {
            using (Process curProcess = Process.GetCurrentProcess())
            using (ProcessModule curModule = curProcess.MainModule)
            {
                return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
            }
        }

        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static bool IsKeyDown(int vk)
        {
            return (GetAsyncKeyState(vk) & 0x8000) != 0;
        }

        private static void SendUnicodeChar(char ch)
        {
            INPUT[] inputs = new INPUT[2];
            inputs[0].type = INPUT_KEYBOARD;
            inputs[0].u.ki.wVk = 0;
            inputs[0].u.ki.wScan = (ushort)ch;
            inputs[0].u.ki.dwFlags = KEYEVENTF_UNICODE;

            inputs[1].type = INPUT_KEYBOARD;
            inputs[1].u.ki.wVk = 0;
            inputs[1].u.ki.wScan = (ushort)ch;
            inputs[1].u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;

            SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
            {
                KBDLLHOOKSTRUCT hookStruct = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));

                // Ignore our own injected keystrokes
                if ((hookStruct.flags & LLKHF_INJECTED) != 0)
                {
                    return CallNextHookEx(_hookID, nCode, wParam, lParam);
                }

                bool shift = IsKeyDown(VK_SHIFT);
                bool ctrl = IsKeyDown(VK_CONTROL);
                bool alt = IsKeyDown(VK_MENU);

                if (!ctrl && !alt)
                {
                    uint vk = hookStruct.vkCode;
                    uint sc = hookStruct.scanCode;

                    if (_mode == "jis-legend" || _mode == "both")
                    {
                        // Hardware ScanCodes on top number row (identical across US 101 & JIS 106 drivers):
                        // ScanCode 0x09 (Key '8'): Shift + 8 -> '(' (matches JIS keycap legend)
                        if (shift && sc == 0x09) { SendUnicodeChar('('); return (IntPtr)1; }
                        // ScanCode 0x0A (Key '9'): Shift + 9 -> ')' (matches JIS keycap legend)
                        if (shift && sc == 0x0A) { SendUnicodeChar(')'); return (IntPtr)1; }
                        // ScanCode 0x0B (Key '0'): Shift + 0 -> ')' (handles US muscle memory too; unshifted '0' stays '0')
                        if (shift && sc == 0x0B) { SendUnicodeChar(')'); return (IntPtr)1; }
                        // ScanCode 0x0C (Key '-'): Shift + - -> '=' (matches JIS keycap legend '=')
                        if (shift && sc == 0x0C) { SendUnicodeChar('='); return (IntPtr)1; }
                        // ScanCode 0x0D (Key right of '-', '^' on JIS / '=' on US): unshifted -> '=', shifted -> '+'
                        if (sc == 0x0D) { SendUnicodeChar(shift ? '+' : '='); return (IntPtr)1; }
                        // ScanCode 0x73 (JIS '_' Ro key next to Right Shift): unshifted/shifted -> '_'
                        if (sc == 0x73) { SendUnicodeChar('_'); return (IntPtr)1; }
                    }

                    if (_mode == "rescue" || _mode == "both")
                    {
                        // Japanese Muhenkan (Left of Space: ScanCode 0x7B / VK 0x1D) OR F9 (ScanCode 0x43 / VK 0x78) -> '(' or '8'
                        if (sc == 0x7B || vk == 0x1D || vk == 0x78)
                        {
                            SendUnicodeChar(shift ? '8' : '(');
                            return (IntPtr)1;
                        }
                        // Japanese Henkan (Right of Space: ScanCode 0x79 / VK 0x1C) OR F10 (ScanCode 0x44 / VK 0x79) -> ')' or '9'
                        if (sc == 0x79 || vk == 0x1C || vk == 0x79)
                        {
                            SendUnicodeChar(shift ? '9' : ')');
                            return (IntPtr)1;
                        }
                        // Japanese Kana (ScanCode 0x70 / VK 0xF2 / 0x15) OR Yen (ScanCode 0x7D) OR F11 (VK 0x7A) -> '=' or '+'
                        if (sc == 0x70 || vk == 0xF2 || vk == 0x15 || sc == 0x7D || vk == 0x7A)
                        {
                            SendUnicodeChar(shift ? '+' : '=');
                            return (IntPtr)1;
                        }
                        // F12 (VK 0x7B) in rescue mode -> '-' or '_'
                        if (vk == 0x7B)
                        {
                            SendUnicodeChar(shift ? '_' : '-');
                            return (IntPtr)1;
                        }
                    }
                }
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KBDLLHOOKSTRUCT
        {
            public uint vkCode;
            public uint scanCode;
            public uint flags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public int type;
            public InputUnion u;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)] public KEYBDINPUT ki;
            [FieldOffset(0)] public MOUSEINPUT mi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        private static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    }
}
'@

    [System.IO.File]::WriteAllText($csPath, $csCode, [System.Text.Encoding]::UTF8)

    # Compile with built-in .NET C# compiler
    Add-Type -TypeDefinition $csCode -ReferencedAssemblies "System.Windows.Forms" -OutputAssembly $exePath -OutputType WindowsApplication

    # Start background process immediately
    Start-Process -FilePath $exePath -ArgumentList $FixerMode -WindowStyle Hidden

    # Register in User Startup folder so it persists across reboots
    $startupDir = [Environment]::GetFolderPath("Startup")
    $lnkPath = Join-Path $startupDir "SurfaceKeyFixer.lnk"
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut($lnkPath)
    $sc.TargetPath = $exePath
    $sc.Arguments = $FixerMode
    $sc.WorkingDirectory = $BinDir
    $sc.WindowStyle = 7
    $sc.Description = "Surface Japanese Keyboard ()= Fixer"
    $sc.Save()
}

Backup-KeyboardRegistry
$i8042Path = "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters"

switch ($Mode) {
    "HybridInstant" {
        Build-And-Start-KeyFixer "jis-legend"
        Write-Host ""
        Write-Host (U "  [OK] \u0110\u00C3 B\u1EACT CH\u1EBE \u0110\u1ED8 LAI TH\u00D4NG MINH (T\u00C1C D\u1EE4NG NGAY - KH\u00D4NG C\u1EA6N REBOOT!)") -ForegroundColor Green
        Write-Host (U "       - B\u1EA5m Shift + 8  --> ra d\u1EA5u m\u1EDF ngo\u1EB7c '(' (\u0111\u00FAng nh\u01B0 in tr\u00EAn m\u1EB7t ph\u00EDm Nh\u1EADt)") -ForegroundColor White
        Write-Host (U "       - B\u1EA5m Shift + 9  --> ra d\u1EA5u \u0111\u00F3ng ngo\u1EB7c ')' (\u0111\u00FAng nh\u01B0 in tr\u00EAn m\u1EB7t ph\u00EDm Nh\u1EADt)") -ForegroundColor White
        Write-Host (U "       - B\u1EA5m Shift + -  --> ra d\u1EA5u b\u1EB1ng '=' (\u0111\u00FAng nh\u01B0 in tr\u00EAn m\u1EB7t ph\u00EDm Nh\u1EADt)") -ForegroundColor White
        Write-Host (U "       - C\u00E1c ph\u00EDm kh\u00E1c gi\u1EEF nguy\u00EAn quen tay. H\u00E3y m\u1EDF Notepad/Zalo g\u00F5 th\u1EED ngay!") -ForegroundColor Cyan
    }
    "DeadKeyRescue" {
        Build-And-Start-KeyFixer "both"
        Write-Host ""
        Write-Host (U "  [OK] \u0110\u00C3 B\u1EACT CH\u1EBE \u0110\u1ED8 C\u1EE8U PH\u00CDM LI\u1EC6T V\u1EACT L\u00DD (T\u00C1C D\u1EE4NG NGAY - KH\u00D4NG C\u1EA6N REBOOT!)") -ForegroundColor Green
        Write-Host (U "       1) N\u00FAt [\u7121\u5909\u63DB Muhenkan - b\u00EAn tr\u00E1i Space] ho\u1EB7c [F9]  --> G\u00F5 '(' (Gi\u1EEF Shift ra '8')") -ForegroundColor White
        Write-Host (U "       2) N\u00FAt [\u5909\u63DB Henkan - b\u00EAn ph\u1EA3i Space]   ho\u1EB7c [F10] --> G\u00F5 ')' (Gi\u1EEF Shift ra '9')") -ForegroundColor White
        Write-Host (U "       3) N\u00FAt [\u30AB\u30BF\u30AB\u30CA Kana / \u00A5]               ho\u1EB7c [F11] --> G\u00F5 '=' (Gi\u1EEF Shift ra '+')") -ForegroundColor White
        Write-Host (U "       4) N\u00FAt [_ Ro - c\u1EA1nh Shift ph\u1EA3i]                    --> G\u00F5 '-' (Gi\u1EEF Shift ra '_')") -ForegroundColor White
        Write-Host (U "       5) Ngo\u00E0i ra Shift+8='(', Shift+9=')', Shift+-='=' c\u0169ng \u0111\u01B0\u1EE3c b\u1EADt s\u1EB5n!") -ForegroundColor Cyan
    }
    "JIS106" {
        Set-ItemProperty -Path $i8042Path -Name "LayerDriver JPN" -Value "kbd106.dll" -Type String
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardIdentifier" -Value "PCAT_106KEY" -Type String
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardType" -Value 7 -Type DWord
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardSubtype" -Value 2 -Type DWord
        # Also enable instant hook so user doesn't even have to wait for reboot to test ()=
        Build-And-Start-KeyFixer "jis-legend"
        Write-Host ""
        Write-Host (U "  [OK] \u0110\u00C3 CHUY\u1EC2N DRIVER WINDOWS SANG CHU\u1EA8N NH\u1EACT JIS 106/109 PH\u00CDM (kbd106.dll)") -ForegroundColor Green
        Write-Host (U "       - \u0110\u00E3 b\u1EADt k\u00E8m KeyFixer \u0111\u1EC3 g\u00F5 '() = ' \u0103n ngay l\u1EADp t\u1EE9c.") -ForegroundColor White
        Write-Host (U "       - Sau khi kh\u1EDFi \u0111\u1ED9ng l\u1EA1i m\u00E1y, 100% k\u00FD t\u1EF1 in tr\u00EAn m\u1EB7t ph\u00EDm Nh\u1EADt s\u1EBD kh\u1EDBp tuy\u1EC7t \u0111\u1ED1i!") -ForegroundColor Cyan
    }
    "US101" {
        Stop-KeyFixer
        $startupLnk = Join-Path ([Environment]::GetFolderPath("Startup")) "SurfaceKeyFixer.lnk"
        if (Test-Path $startupLnk) { Remove-Item $startupLnk -Force }
        Set-ItemProperty -Path $i8042Path -Name "LayerDriver JPN" -Value "kbd101.dll" -Type String
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardIdentifier" -Value "PCAT_101KEY" -Type String
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardType" -Value 7 -Type DWord
        Set-ItemProperty -Path $i8042Path -Name "OverrideKeyboardSubtype" -Value 0 -Type DWord
        Write-Host ""
        Write-Host (U "  [OK] \u0110\u00C3 CHUY\u1EC2N DRIVER WINDOWS SANG CHU\u1EA8N M\u1EE8 US 101/102 PH\u00CDM (kbd101.dll)") -ForegroundColor Green
        Write-Host (U "       - Shift + 9 = '(' | Shift + 0 = ')' | Ph\u00EDm '^' c\u1EA1nh Backspace = '=' v\u00E0 '+'") -ForegroundColor White
        Write-Host (U "       - Kh\u1EDFi \u0111\u1ED9ng l\u1EA1i Windows n\u1EBFu tr\u01B0\u1EDBc \u0111\u00F3 m\u00E1y \u0111ang k\u1EB9t driver JIS.") -ForegroundColor Cyan
    }
    "Rollback" {
        Stop-KeyFixer
        $startupLnk = Join-Path ([Environment]::GetFolderPath("Startup")) "SurfaceKeyFixer.lnk"
        if (Test-Path $startupLnk) { Remove-Item $startupLnk -Force }
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map" -ErrorAction SilentlyContinue
        $regBackupFile = Join-Path $BackupDir "i8042prt-initial.reg"
        if (Test-Path $regBackupFile) {
            reg import "$regBackupFile" | Out-Null
        }
        pnputil /scan-devices | Out-Null
        Write-Host ""
        Write-Host (U "  [OK] \u0110\u00C3 KH\u00D4I PH\u1EE4C NGUY\u00CAN TR\u1EA0NG BAN \u0110\u1EA6U & QU\u00C9T L\u1EA0I DRIVER B\u00C0N PH\u00CDM.") -ForegroundColor Yellow
    }
}
