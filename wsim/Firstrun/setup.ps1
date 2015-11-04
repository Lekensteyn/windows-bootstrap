
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$needsReboot = $False

function Set-RegProperty($key, $name, $value, $type="dword") {
    # Forcefully create a property, assuming that $key already exists
    New-ItemProperty "$key" "$name" -PropertyType $type -Value "$value" -Force
}

# Disable useless scheduled tasks (find those with schtasks /query)
$tasknames = @(
"Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
"Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
"Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
"Microsoft\Windows\Defrag\ScheduledDefrag",
"Microsoft\Windows\Diagnosis\Scheduled",
"Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
"Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
"Microsoft\Windows\RAC\RacTask",
"Microsoft\Windows\SystemRestore\SR",
"Microsoft\Windows\Windows Error Reporting\QueueReporting",
"Microsoft\Windows\WindowsBackup\ConfigNotification",
"Microsoft\Windows Defender\MP Scheduled Scan"
)
foreach ($tn in $tasknames) {
    schtasks /Change /TN "$tn" /disable
}

# Stop and disable useless services. Found with:
# Get-Service | Where-Object {$_.status -eq "running"}
$services = @(
"Background Intelligent Transfer Service",
"Disk Defragmenter",
"IP Helper",
"Diagnostic Policy Service",
"Network Connections",
"Network List Service",
"Network Location Awareness",
"Program Compatibility Assistant Service",
"Desktop Window Manager Session Manager",
"Print Spooler",
"Security Center",
"SSDP Discovery",
"Superfetch",
# "TCP/IP NetBIOS Helper", # Needed for shared folders.
# "Themes",
# "Windows Audio",
# "Windows Audio Endpoint Builder",
"Windows Event Collector",
"Windows Error Reporting Service",
"Windows Defender",
# "Windows Event Log",
# "Windows Firewall",
"Windows Search",
"Windows Update"
)
foreach ($svc in $services) {
    Get-Service "$svc" | Stop-Service -Force -PassThru | Set-Service -StartupType disabled
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
