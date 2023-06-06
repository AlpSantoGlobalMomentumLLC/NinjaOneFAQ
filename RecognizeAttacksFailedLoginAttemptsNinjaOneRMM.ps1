# Made for not only for NinjaOne. Easy adaptable, if you remove the NinjaOne Part at the End.

# Axel Christian Lenz 
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/Erkenne-Angriffe-durch-fehlgeschlagene-Anmeldeversuche-Win-sicher-mit-NinjaOne-RMM
# https://translated.turbopages.org/proxy_u/de-en.en.052ab67b-647fb5f4-d6909c31-74722d776562/https/ninjaonefaq.dcms.site/post/Erkenne-Angriffe-durch-fehlgeschlagene-Anmeldeversuche-Win-sicher-mit-NinjaOne-RMM
# For NinjaOne you have to run it in the User Context.

# Dieses PowerShell-Skript dient zur Erkennung von gescheiterten Anmeldeversuchen auf einem Windows-System. 
# Es durchsucht den Security Event Log auf Ereignisse mit der ID 4625 (gescheiterte Anmeldungen) in einem bestimmten Zeitrahmen, der durch den Parameter daysBack definiert wird. 
# Die gesammelten Ereignisse werden verarbeitet und gruppiert, um eine Benutzerübersicht mit der Anzahl der gescheiterten Anmeldeversuche zu erstellen.
# Es erzeugt schließlich eine Warnung, wenn die Anzahl der fehlgeschlagenen Anmeldungen für einen Benutzer einen vorgegebenen Schwellenwert überschreitet, und meldet ein allgemeines "OK", wenn keine ungewöhnlichen Aktivitäten festgestellt werden.
# Mit der optionalen Funktion useComputerNameFilter kann das Skript so konfiguriert werden, dass es Ereignisse ignoriert, die auf den lokalen Computernamen (hostname) zurückzuführen sind.
# Es schreibt die Ereignisse in die Console und in ein NinjaOne MultiLine Feld.

# This PowerShell script is used to detect failed logon attempts on a Windows system. 
# It scans the Security Event Log for events with ID 4625 (failed logins) in a specified time frame defined by the daysBack parameter. 
# It processes the collected events and groups them to create a user summary with the number of failed logon attempts.
# It eventually generates a warning if the number of failed logins for a user exceeds a specified threshold, and reports a general "OK" if no unusual activity is detected.
# It writes the events to the Console and to a NinjaOne MultiLine field.
# Inspiration: https://adamtheautomator.com/windows-security-events/
# The optional useComputerNameFilter function can be used to configure the script to ignore events that are due to the local computer name (hostname).

# -daysBack "1" -threshold "1" -useComputerNameFilter $true
# -daysBack "1" -threshold "10" -useComputerNameFilter "true"
# -daysBack "1" -threshold "10" -useComputerNameFilter "false"

# Idea for the future: Make it in a hour base like this one https://ninjarmm.zendesk.com/hc/en-us/community/posts/360078080552-Brute-Force-Attack-Detection-Script-Script-Result-Condition-

<#
    [int]$threshold = 1, # threshold value for the number of events
    #[bool]$useComputerNameFilter = $false # if true, the local computer name will be used in the filter
    # Workaround because NinjaOne seems to have a problem.
    [string]$useComputerNameFilter = "false" # if true, the local computer name will be used in the filter
#>
param(
    [int]$daysBack = 1, # Anzahl der zurückliegenden Tage, die betrachtet werden soll
    [int]$threshold = 1,  # Schwellenwert für die Anzahl der Ereignisse
    #[bool]$useComputerNameFilter = $false # Wenn true, wird der lokale Computername im Filter verwendet
    # Workaround weil NinjaOne ein Problem zu haben scheint.
    [string]$useComputerNameFilter = "false" # Wenn true, wird der lokale Computername im Filter verwendet
)

# Erstellen Sie die numerische Wert-zu-Zeichenkette "Karte"
$logonTypes = @{
    [uint32]2 = "Interactive"
    [uint32]3 = "Network"
    [uint32]4 = "Batch"
    [uint32]5 = "Service"
    [uint32]7 = "Unlock"
    [uint32]8 = "NetworkCleartext"
    [uint32]9 = "NewCredentials"
    [uint32]10 = "RemoteInteractive"
    [uint32]11 = "CachedInteractive"
}

# Wählen wir erstmal einen Zeitrahmen (in diesem Fall die Anzahl der Tage, die durch $daysBack definiert ist)
$DTStart = (Get-Date).AddDays(-$daysBack).Date
$DTEnd = Get-Date

# Ermitteln des Computernamens
$computerName = $env:COMPUTERNAME

# Nun fahnden wir nach allen Ereignissen mit der ID 4625 innerhalb des oben festgelegten Zeitrahmens
<#if($useComputerNameFilter) {
    $events = Get-WinEvent -FilterHashTable @{LogName='Security';ID=4625;StartTime=$DTStart;EndTime=$DTEnd} | Where-Object { $_.Properties[5].Value -ne $computerName }
}
else {
    $events = Get-WinEvent -FilterHashTable @{LogName='Security';ID=4625;StartTime=$DTStart;EndTime=$DTEnd}
}
#>

if($useComputerNameFilter -eq "true") {
    $events = Get-WinEvent -FilterHashTable @{LogName='Security';ID=4625;StartTime=$DTStart;EndTime=$DTEnd} | Where-Object { $_.Properties[5].Value -ne $computerName }
}
else {
    $events = Get-WinEvent -FilterHashTable @{LogName='Security';ID=4625;StartTime=$DTStart;EndTime=$DTEnd}
}



# Erstellen Sie ein Array von benutzerdefinierten PowerShell-Objekten, um die relevanten Ereigniseigenschaften auszugeben
$processedEvents = $events | ForEach-Object {
    # Suchen Sie den numerischen Wert in der Hashtabelle
    $logonType = $logonTypes[$_.properties[10].value] 
    [PSCustomObject]@{     
        TimeCreated = $_.TimeCreated     
        TargetUserName = $_.properties[5].value     
        LogonType = $logonType     
        WorkstationName = $_.properties[13].value     
        IpAddress = $_.properties[19].value 
    }
}

# Gruppieren Sie die verarbeiteten Ereignisse nach TargetUserName und sortieren Sie sie nach der Anzahl der Ereignisse
$groupedEvents = $processedEvents | Group-Object -Property TargetUserName | Sort-Object -Property Count -Descending

# Überprüfen Sie, ob die Anzahl der Ereignisse für irgendeinen Benutzer den Schwellenwert überschreitet
$attacks = $groupedEvents | Where-Object { $_.Count -ge $threshold }
###

if ($attacks) {
    Write-Host "WARNING! The following users have had a large number of failed logon attempts:"
    $attacks2 = $attacks | Format-Table -Wrap | Out-String
    Write-Host $attacks2
    Ninja-Property-Set faildLogins $attacks2 | Out-Null
} else {
    # Alles in Ordnung, kein Grund zur Sorge!
    Write-Host "All good!"
    Ninja-Property-Set faildLogins 'OK' | Out-Null
}
