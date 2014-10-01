
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$needsReboot = $False

# Unhide files in Explorer
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
# Show hidden files, folders, and drives
Set-ItemProperty $key Hidden 1
# Hide extensions for known file types
Set-ItemProperty $key HideFileExt 0
# Hide protected operating system files (Recommended)
Set-ItemProperty $key ShowSuperHidden 1
Stop-Process -processname explorer

# Disable a single pagefile if any
$pg = gwmi win32_pagefilesetting
if ($pg) {
    $pg.Delete()
}

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
