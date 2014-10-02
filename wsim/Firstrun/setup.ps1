
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$needsReboot = $False

function Set-RegProperty($key, $name, $value, $type="dword") {
    # Forcefully create a property, assuming that $key already exists
    New-ItemProperty "$key" "$name" -PropertyType $type -Value "$value" -Force
}

# Configure Windows Explorer properties
$explorer_key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"

$key = "$explorer_key\Advanced"
New-Item $key -Force
# Show hidden files, folders, and drives
Set-RegProperty $key Hidden 1
# Hide extensions for known file types
Set-RegProperty $key HideFileExt 0
# Hide protected operating system files (Recommended)
Set-RegProperty $key ShowSuperHidden 1

$key = "$explorer_key\HideDesktopIcons\NewStartPanel"
New-Item $key -Force
# Show "Computer" desktop icon"
Set-RegProperty $key "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 0
#Stop-Process -processname explorer

# Disable automatic pagefile management
$cs = gwmi Win32_ComputerSystem
if ($cs.AutomaticManagedPagefile) {
    $cs.AutomaticManagedPagefile = $False
    $cs.Put()
}
# Disable a single pagefile if any
$pg = gwmi win32_pagefilesetting
if ($pg) {
    $pg.Delete()
}

# Disable hibernation
& powercfg /h off

# Try to activate Windows if not already activated
$act = cscript $env:SystemRoot\System32\slmgr.vbs /dli
if ("$act" -NotLike '*Licensed*') {
    # Try to execute a helper for activation, requesting reboot on succes.
    & "$PSScriptRoot\slactivate"
    $needsReboot = $?
}

if ($needsReboot) {
    Restart-Computer
}
# vim: set sw=4 et ts=4:
