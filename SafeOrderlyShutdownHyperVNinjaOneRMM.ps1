# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/Sicher-und-geordnet-VMs-mit-Stil-herunterfahren
# https://translated.turbopages.org/proxy_u/de-en.en.b1691819-647fb772-0bc263a3-74722d776562/https/ninjaonefaq.dcms.site/post/Sicher-und-geordnet-VMs-mit-Stil-herunterfahren

# Dieses Skript enthält drei Hauptfunktionen: 
# Stop-VMGracefully, Get-VMStatus und WaitForAllOffAndExecuteCommand. 
# Es wurde entwickelt, um mehrere virtuelle Maschinen (VMs) in der angegebenen $vmList sicher und geordnet herunterzufahren.
# Die Funktion Stop-VMGracefully fährt die VMs nacheinander herunter, während die Funktion Get-VMStatus den Status aller VMs überprüft und zurückgibt, ob alle VMs ausgeschaltet sind oder nicht.
# WaitForAllOffAndExecuteCommand wartet, bis alle VMs ausgeschaltet sind, und führt dann den einen Reboot Befehl aus.
# Ziel: Der Hyper-V-Server neu gestartet, nachdem bestimmte VMs heruntergefahren wurden.
# Zusätzlich zu diesen Funktionen meldet das Skript alle interaktiv angemeldeten Benutzer ab, damit der Shutdown bzw. Reboot nicht verhindert wird.

# Optimierungsmöglichkeiten:
#   Bei mehreren VMs wartet im Moment ein Shutdown auf den anderen.
# 	Man könnte es mittels Parameterübergabe Universell machen.

# Sicherheitsmechanismen:
# 1. Obwohl das Skript eigentlich automatisch auf den Shutdown warten sollte, prüfe ich noch mal ob die VM down ist.
# 2. Vor dem Start schaut es ob es auf dem richtigen Rechner gestartet ist.
# 3. Die Benutzer werden forciert abgemeldet, damit der Shutdown nicht an einem offenen Notepad hängen bleibt. (Bei einem Shutdown /f /r würden hingegen auch auf Dienste nicht gewartet, das beim Exchange eher unschön ist.)

# https://www.linkedin.com/in/axellenz/

# Englisch:
# This script contains three main functions: 
# Stop-VMGracefully, Get-VMStatus, and WaitForAllOffAndExecuteCommand.
# It is designed to safely and orderly shut down multiple virtual machines (VMs) specified in the `$vmList`.
# The Stop-VMGracefully function shuts down the VMs one by one, while the Get-VMStatus function checks the status of all the VMs and returns whether all VMs are turned off or not.
# WaitForAllOffAndExecuteCommand waits until all VMs are turned off and then executes Shutdown /r command. 
# The Hyper-V server is rebooted after all the VMs have been shut down.
# In addition to these functions, the script logs off all interactively logged-on users from the Hyper-V installation. 


#Zur Sicherheit wird der Host geprüft -> $requiredHostName = "YourRequiredVMHostName"
$requiredHostName = "LZRSRVVMHOST01"

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




# Beispiel: Gebe die Namen der VMs als kommagetrennte Liste an 
$vmList = @("LZRSRVEX02")
#$vmList = @("alt LZRSRVDB01", "LZRSRVEX02")


# Shutdown für alle VMs in der $vmList
Stop-VMGracefully -VMNames $vmList

# Reboot des Hyper-V Servers, mit Sicherheitsüberprüfung ob die Server in der $vmList herunter gefahren sind.
# Zum Testen ## WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/i" }
# Zum Testen ## WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/i", "-t 5" }
WaitForAllOffAndExecuteCommand -VMNames $vmList -CommandToExecute { Start-Process "shutdown" -ArgumentList "/r" }

# Abmeldung aller Benutzer von der Hyper-V (Domain Member)
 Invoke-CimMethod -ClassName Win32_Operatingsystem -ComputerName $env:COMPUTERNAME -MethodName Win32Shutdown -Arguments @{ Flags = 4 }
