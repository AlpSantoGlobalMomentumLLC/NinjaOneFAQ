# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# Beschreibung: https://ninjaonefaq.dcms.site/post/Das-ultimative-Pending-Reboot-Script-Der-Ausloser-fur-das-User-Nagging-Script-NinjaOne-RMM
# Description AutoTranslated: https://translated.turbopages.org/proxy_u/de-en.en.4f33b3a3-647fae72-fca390c4-74722d776562/https/ninjaonefaq.dcms.site/post/Das-ultimative-Pending-Reboot-Script-Der-Ausloser-fur-das-User-Nagging-Script-NinjaOne-RMM

$ErrorActionPreference = "SilentlyContinue"

# Diese Funktion prüft, ob ein Neustart des Systems aussteht.
function Test-PendingReboot {
    # Erst listen wir alle Registrierungsschlüssel auf, die wir überprüfen wollen.
    $keysToCheck = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts"
    )

    # Dann prüfen wir nacheinander jeden Schlüssel.
    foreach ($key in $keysToCheck) {
        # Wenn ein Schlüssel existiert, dann ist ein Neustart erforderlich.
        if (Test-Path -Path $key) { return $true }
    }

    # Jetzt listen wir alle Registrierungswerte auf, die wir überprüfen wollen.
    $valuesToCheck = @(
        @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing", "RebootInProgress"),
        @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing", "PackagesPending"),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager", "PendingFileRenameOperations"),
        @("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager", "PendingFileRenameOperations2"),
        @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", "DVDRebootSignal"),
        @("HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon", "JoinDomain"),
        @("HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon", "AvoidSpnSet")
    )

    # Dann prüfen wir nacheinander jeden Wert.
    foreach ($value in $valuesToCheck) {
        # Wenn ein Wert existiert, dann ist ein Neustart erforderlich.
        if ((Get-ItemProperty -Path $value[0] -Name $value[1] -ErrorAction SilentlyContinue) -ne $null) { return $true }
    }

    # Hier versuchen wir herauszufinden, ob ein Neustart ausstehend ist, indem wir eine Methode aus dem CCM_ClientUtilities WMI-Klasse aufrufen.
    try {
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($status -ne $null) -and $status.RebootPending) {
            return $true
        }
    }
    catch { }

    # Wenn keiner der oben genannten Prüfpunkte zutrifft, ist kein Neustart erforderlich.
    return $false
}

# Wir rufen die Funktion auf, um zu prüfen, ob ein Neustart aussteht.
Test-PendingReboot
