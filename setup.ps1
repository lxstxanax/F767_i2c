# setup.ps1 — run once on each new machine before first debug session
#
# What it does:
#   1. Finds STM32CubeCLT installation
#   2. Fixes the broken STLinkUSBDriver.dll in GDB server (v6.1.2 bug with V2J47 firmware)
#   3. Updates stm32.cltPath in .vscode/settings.json to match this machine

param(
    [string]$CltPath = ""
)

$ErrorActionPreference = "Stop"

# --- Find CLT if not specified ---
if (-not $CltPath) {
    $candidates = Get-ChildItem "C:\ST" -Filter "STM32CubeCLT*" -ErrorAction SilentlyContinue |
                  Sort-Object Name -Descending |
                  Select-Object -First 1
    if ($candidates) {
        $CltPath = $candidates.FullName
    } else {
        Write-Error "STM32CubeCLT not found in C:\ST\. Pass -CltPath 'C:\ST\STM32CubeCLT_x.x.x'"
        exit 1
    }
}

Write-Host "Using CLT: $CltPath" -ForegroundColor Cyan

# --- Fix STLinkUSBDriver.dll ---
$gdbDll  = "$CltPath\STLink-gdb-server\bin\native\win_x64\STLinkUSBDriver.dll"
$progDll = "$CltPath\STM32CubeProgrammer\bin\STLinkUSBDriver.dll"

if (-not (Test-Path $gdbDll))  { Write-Error "Not found: $gdbDll";  exit 1 }
if (-not (Test-Path $progDll)) { Write-Error "Not found: $progDll"; exit 1 }

$gdbVer  = (Get-Item $gdbDll).VersionInfo.FileVersion
$progVer = (Get-Item $progDll).VersionInfo.FileVersion

if ($gdbVer -ne $progVer) {
    $bak = "$gdbDll.bak"
    if (-not (Test-Path $bak)) { Copy-Item $gdbDll $bak }
    Copy-Item $progDll $gdbDll -Force
    Write-Host "DLL fixed: $gdbVer -> $progVer" -ForegroundColor Green
} else {
    Write-Host "DLL OK: v$gdbVer" -ForegroundColor Green
}

# --- Update .vscode/settings.json ---
$settingsFile = "$PSScriptRoot\.vscode\settings.json"
if (Test-Path $settingsFile) {
    $raw = Get-Content $settingsFile -Raw
    # Replace the cltPath value (handles forward and back slashes)
    $cltFwd = $CltPath -replace '\\', '/'
    $raw = $raw -replace '"stm32\.cltPath"\s*:\s*"[^"]*"', """stm32.cltPath"": ""$cltFwd"""
    Set-Content $settingsFile $raw -Encoding UTF8
    Write-Host "settings.json updated: stm32.cltPath = $cltFwd" -ForegroundColor Green
}

Write-Host ""
Write-Host "Setup complete. Open project in VS Code and press F5." -ForegroundColor Cyan
