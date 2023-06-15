# https://www.linkedin.com/in/axellenz/
# Das Skript prüft, ob ein Neustart des Computers aussteht und ermittelt den Grund dafür.
# Wir überprüfen dazu verschiedene Registrierungsschlüssel und -werte, die auf einen ausstehenden Neustart hindeuten. 
# Zusätzlich verwenden wir die WMI-Methode DetermineIfRebootPending(), um festzustellen, ob ein Neustart ausstehend ist.
# Wenn ein ausstehender Neustart gefunden wird, gibt das Skript den Grund dafür in das NinjaOne-Feld "pendingRebootGrund" aus.
# Ist kein Neustart erforderlich, wird "No Pending reboot" ins Feld geschrieben. (Multi Line Feld)

# The script checks if a computer restart is pending and determines the reason for it.
# We do this by examining various registry keys and values that indicate a pending restart.
# Additionally, we use the WMI method DetermineIfRebootPending() to determine if a restart is pending.
# If a pending restart is found, the script outputs the reason for it into the NinjaOne field "pendingRebootGrund".
# If no restart is required, the script writes "No Pending reboot" into the field (multi-line field).


$ErrorActionPreference = "SilentlyContinue"

function Test-PendingReboot {
    $keysToCheck = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts"
    )

    $pendingReasons = @()

    foreach ($key in $keysToCheck) {
        if (Test-Path -Path $key) { $pendingReasons += "Registry key: $key" }
    }

    $valuesToCheck = @(
        @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing", "RebootInProgress"),
        @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing", "PackagesPending"),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager", "PendingFileRenameOperations"),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager", "DUMMY"),
        @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", "DVDRebootSignal"),
        @("HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon", "JoinDomain"),
        @("HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon", "AvoidSpnSet")
    )

    foreach ($value in $valuesToCheck) {
        if ((Get-ItemProperty -Path $value[0] -Name $value[1] -ErrorAction SilentlyContinue) -ne $null) { $pendingReasons += "Registry value: $($value[0].Replace(':', '')) $value[1]" }
    }

    try {
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($status -ne $null) -and $status.RebootPending) {
            $pendingReasons += "WMI: DetermineIfRebootPending"
        }
    }
    catch { }

    return $pendingReasons
}

$pendingReasons = Test-PendingReboot
$ReasonOutput = $pendingReasons -join "`n"

if ($ReasonOutput) {
    Ninja-Property-Set pendingRebootGrund $ReasonOutput | Out-Null
    Write-Output "Reboot pending"
    Write-Output $ReasonOutput
} else {
    Ninja-Property-Set pendingRebootGrund 'No Pending Reboot' | Out-Null
    Write-Output "No Pending reboot"
}
