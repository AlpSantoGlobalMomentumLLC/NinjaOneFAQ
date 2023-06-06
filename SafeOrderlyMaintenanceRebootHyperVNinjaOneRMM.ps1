# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/

# Dieses Skript ist ein umfassendes Werkzeug zur Verwaltung von Hyper-V-Servern und VMs
# Es beinhaltet Funktionen wie Stop-VMGracefully zum geordneten Herunterfahren von VMs und Get-VMStatus zur Überwachung des VM-Status.
# Außerdem ermöglicht WaitForAllOffAndExecuteCommand das kontrollierte Neustarten des Hyper-V-Servers nach dem Herunterfahren der VMs.
# Zusätzlich zum Herunterfahren und Neustarten bietet das Skript Funktionen wie Set-MaintenanceMode, um den Wartungsmodus für VMs und Host für 15 Min zu aktivieren und
# (Wichtig Ignoriert werden VMs die mit # Anfangen.)
# Get-AccessToken zur Authentifizierung mit einer REST API.
# Es stellt sicher, dass alle Benutzer abgemeldet sind, bevor der Neustart erfolgt (Damit er nicht daran hängen bleibt aber ohne den ganzen Reboot forced zu machen), und prüft den korrekten Hostnamen vor dem Start.
#Das Skript ist auch mit Sicherheitsmechanismen ausgestattet, um mögliche Probleme zu verhindern.

# Optimierungsmöglichkeiten:
#   Bei mehreren VMs wartet im Moment ein Shutdown auf den anderen.
#            Man könnte es mittels Parameterübergabe Universell machen.

# Sicherheitsmechanismen:
# 1. Obwohl das Skript eigentlich automatisch auf den Shutdown warten sollte, prüfe ich noch mal ob die VM down ist.
# 2. Vor dem Start schaut es ob es auf dem richtigen Rechner gestartet ist.
# 3. Die Benutzer werden forciert abgemeldet, damit der Shutdown nicht an einem offenen Notepad hängen bleibt. (Bei einem Shutdown /f /r würden hingegen auch auf Dienste nicht gewartet, das beim Exchange eher unschön ist.)

# https://www.linkedin.com/in/axellenz/

# Englisch:
# This script is a comprehensive tool for managing Hyper-V servers and VMs. It includes functions such as Stop-VMGracefully for orderly shutting down VMs, and Get-VMStatus for monitoring the status of VMs. Furthermore, WaitForAllOffAndExecuteCommand allows for a controlled restart of the Hyper-V server after the VMs have shut down. In addition to shutting down and restarting, the script provides features such as Set-MaintenanceMode to enable maintenance mode for VMs and Get-AccessToken for authentication with a REST API. It ensures that all users are logged off before restarting and checks for the correct hostname before starting. The script is also equipped with safety mechanisms to prevent potential issues.


#Zur Sicherheit wird der Host geprüft -> $requiredHostName = "YourRequiredVMHostName"
$requiredHostName = "FIRMASRVVMHOST01"

if ($env:COMPUTERNAME -ne $requiredHostName) {
    Write-Warning "Der lokale Hostname entspricht nicht dem erforderlichen Hostnamen ($requiredHostName). Beende das Skript."
    Exit 1
}

function Stop-VMGracefully {
    param (
        [string[]]$VMNames
    )

    if (Get-Command -Name Get-VM -ErrorAction SilentlyContinue) {
        foreach ($VMName in $VMNames) {
            try {
                $VM = Get-VM -Name $VMName -ErrorAction Stop

                if ($VM.State -eq 'Running') {
                    Write-Output "VM ${VMName} wird heruntergefahren..."
                    #Stop-VM -Name $VMName -Save -Force -Confirm:$false
                    #Stop-VM -Name $VMName -Force -Confirm:$false
                    Invoke-CimMethod -ClassName Win32_Operatingsystem -ComputerName $vm -MethodName Win32Shutdown -Arguments @{ Flags = 4 }
                    Stop-VM -Name $VMName -Confirm:$false
                } else {
                    Write-Warning "VM ${VMName} ist nicht in Betrieb. Herunterfahren nicht möglich."
                }
            } catch {
                Write-Warning "VM ${VMName} nicht gefunden und zu wenige Berechtigungen."
            }
        }
    } else {
        Write-Error "Hyper-V-Modul nicht installiert oder nicht als Administrator ausgeführt."
    }
}

function Get-VMStatus {
    param (
        [string[]]$VMNames
    )

    $allOff = $true

    if (Get-Command -Name Get-VM -ErrorAction SilentlyContinue) {
        foreach ($VMName in $VMNames) {
            try {
                $VM = Get-VM -Name $VMName -ErrorAction Stop
                Write-Output "Status der VM ${VMName}: $($VM.State)"
                if ($VM.State -ne 'Off') {
                    $allOff = $false
                }
            } catch {
                Write-Warning "VM ${VMName} nicht gefunden, weil nicht existent oder mit zu geringen Berechtigungen ausgeführt."
                $allOff = $false
            }
        }
    } else {
        Write-Error "Hyper-V-Modul nicht installiert oder nicht als Administrator ausgeführt."
    }

    return $allOff
}

function WaitForAllOffAndExecuteCommand {
    param (
        [string[]]$VMNames,
        [scriptblock]$CommandToExecute
    )

    $allOff = Get-VMStatus -VMNames $VMNames

    while (-not $allOff) {
        Start-Sleep -Seconds 10
        $allOff = Get-VMStatus -VMNames $VMNames
    }

    Write-Output "Alle VMs sind ausgeschaltet. Führe den Befehl aus..."
    & $CommandToExecute
}
#####
function ConvertTo-UnixEpoch {
    [CmdletBinding()]
    [OutputType([Int64])]
    param (
        [Parameter(Mandatory = $True)]
        [Object]$DateTime
    )

    if ($DateTime -is [String]) {
        $DateTime = [DateTime]::Parse($DateTime)
    } elseif ($DateTime -is [Int64]) {
        (Get-Date 01.01.1970).AddSeconds($unixTimeStamp)  
    } elseif ($DateTime -is [DateTime]) {
        $DateTime = $DateTime
    } else {
        Write-Error 'The DateTime parameter must be a DateTime object, a string, or an integer.'
        Exit 1
    }

    $UniversalDateTime = $DateTime.ToUniversalTime()
    $UnixEpochTimestamp = [Int64](Get-Date $UniversalDateTime -UFormat %s).ToString().Substring(0, 11)

    Return $UnixEpochTimestamp
}

function Get-AccessToken {
    param (
        $ClientId,
        $ClientSecret
    )

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
        redirect_uri  = https://localhost
        scope         = "monitoring management"
    }

    $API_AuthHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $API_AuthHeaders.Add("accept", 'application/json')
    $API_AuthHeaders.Add("Content-Type", 'application/x-www-form-urlencoded')

    $auth_token = Invoke-RestMethod -Uri https://eu.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $body
    return $auth_token.access_token
}

function Set-MaintenanceMode {
    param (
        $AccessToken,
        $NodeId,
        $DurationInMinutes
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("accept", 'application/json')
    $headers.Add("Authorization", "Bearer $AccessToken")

    $maintenance_url = https://eu.ninjarmm.com/api/v2/device/$NodeId/maintenance

    $end = ConvertTo-UnixEpoch -DateTime ((Get-Date).AddMinutes($DurationInMinutes))

    $request_body = @{
        disabledFeatures = @("ALERTS")
        end              = $end
    }

    $json = $request_body | ConvertTo-Json

    Invoke-RestMethod -Method PUT -Uri $maintenance_url -Headers $headers -Body $json -ContentType "application/json"
}

function Search-Device {
    param (
        $AccessToken,
        $SearchTerm
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $AccessToken")

    $url = https://eu.ninjarmm.com/api/v2/devices/search?q=$SearchTerm&limit=2
    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers

    return $response.devices | Where-Object { $_.systemName -eq $SearchTerm } | Select-Object -ExpandProperty id
}

function GetVMInventory {
    $VMs = Get-VM
    $FilteredVMs = $VMs | Where-Object { $_.Name -notmatch '^#' }
    return $FilteredVMs
}

function WriteToConsole {
    param($VMs)
    foreach ($VM in $VMs) {
        Write-Output $VM.Name
    }
}

function Get-VMsById {
    param (
        $VMs,
        $AccessToken
    )

    $VMIds = @()
    foreach ($VM in $VMs) {
        $DeviceId = Search-Device -AccessToken $AccessToken -SearchTerm ($VM.Name)
        if ($DeviceId) {
            $VMIds += $DeviceId
        }
    }
    return $VMIds
}
###########################################################################################################################
# Zuerst wird der Client verwendet, um ein Zugriffstoken von NinjaRMM zu erhalten.
$ClientId = "hx_XXXXXXXX"
$ClientSecret = "XXXXX"
$AccessToken = Get-AccessToken -ClientId $ClientId -ClientSecret $ClientSecret

# Jetzt ermitteln wir das VM-Inventar und erstellen eine Liste aller VMs und des Host-Servers.
$VMs = GetVMInventory
$LocalHostName = (Get-WmiObject -Class Win32_ComputerSystem).Name
$LocalHostObject = New-Object -TypeName PSObject -Property @{
    Name = $LocalHostName
}
$HOSTSs = $VMs + $LocalHostObject

#Nun suchen wir nach den IDs für die VM-Liste und dem Host-Server.
$VMIds = Get-VMsById -VMs $HOSTSs -AccessToken $AccessToken

# Für jeden Knoten wird der Wartungsmodus für eine bestimmte Dauer aktiviert.
$DurationInMinutes = 15
foreach ($nodeID in $VMIds) {
    Set-MaintenanceMode -AccessToken $AccessToken -NodeId $nodeID -DurationInMinutes $DurationInMinutes
}

####
# Als nächstes wird eine Beispiel-Liste von VMs definiert, die heruntergefahren werden sollen.
# Beispiel: Gebe die Namen der VMs als kommagetrennte Liste an 
$vmList = @("FIRMASRVEX02")
#$vmList = @("alt FIRMASRVDB01", "FIRMASRVEX02")

# Die VMs aus der Liste werden heruntergefahren.
Stop-VMGracefully -VMNames $vmList


# Wir warten darauf, dass alle VMs ausgeschaltet sind, und führen dann einen Reboot des Hyper-V-Servers durch.
# Zum Testen ## WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/i" }
# Zum Testen ## WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/i", "-t 5" }
WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/r" }


# Zum Schluss wird eine Abmeldung aller Benutzer von der Hyper-V (Domain Member) durchgeführt.
Invoke-CimMethod -ClassName Win32_Operatingsystem -ComputerName $env:COMPUTERNAME -MethodName Win32Shutdown -Arguments @{ Flags = 4 }



