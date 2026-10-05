param([switch]$Uninstall)

# The key that switches the layout, as a scancode. See README for other keys.
$Key = 0x3A  # CapsLock

$TaskName   = 'CapsLock language switch'
$InstallDir = "$env:ProgramFiles\capslock-language-switch"
$Script     = "$InstallDir\language-switch.ps1"

# $Key sends F24 (scancode 76): header, 2 entries incl. terminator, 0076 <- $Key, terminator
$KeyboardKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$ScancodeMap = [byte[]](0,0,0,0, 0,0,0,0, 2,0,0,0, 0x76,0, ($Key -band 0xFF),($Key -shr 8), 0,0,0,0)

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Run as administrator: the key remap is a machine-wide setting.' }

# Ours = a single remap to F24, from whatever key
$current = (Get-ItemProperty $KeyboardKey -ErrorAction SilentlyContinue).'Scancode Map'
$ours    = $current -and $current.Length -eq 20 -and $current[8] -eq 2 -and $current[12] -eq 0x76 -and $current[13] -eq 0

# Stopping the task kills only conhost, the script itself keeps running
Unregister-ScheduledTask $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object CommandLine -match 'language-switch\.ps1' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

if ($Uninstall) {
    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($ours) {
        Remove-ItemProperty $KeyboardKey 'Scancode Map'
        'Uninstalled. Restart Windows to get the key back to normal.'
    } else {
        'Uninstalled.'
    }
    return
}

if ($current -and -not $ours) {
    throw 'Another key remap (Scancode Map) is already set, not overwriting it.'
}

# Program Files, not LOCALAPPDATA: the script runs elevated, so a non-admin must not be able to edit it
New-Item -ItemType Directory -Force $InstallDir | Out-Null
Copy-Item "$PSScriptRoot\language-switch.ps1" $Script -Force

# Elevated: Windows blocks messages from a regular process to admin windows (Task Manager etc.)
# conhost --headless: no console window flashing at logon
$action    = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Script`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
Register-ScheduledTask $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Start-ScheduledTask $TaskName

if ($current -and [BitConverter]::ToString($current) -eq [BitConverter]::ToString($ScancodeMap)) {
    'Installed and running. Press the key to check.'
} else {
    Set-ItemProperty $KeyboardKey 'Scancode Map' $ScancodeMap -Type Binary
    'Installed. Restart Windows, then the key switches the layout.'
}
