# NinjaOne RMM, Intune und Co: Vereinfache Dein Patchmanagement mit dem Winget Script (10k SW P.) / NinjaOne RMM, Intune and Co.: simplify Your patch management with the Winget Script (10k SW. p.)
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-Intune-und-Co-Vereinfache-Dein-Patchmanagement-mit-dem-Winget-Script-10k-SW-P
# https://translated.turbopages.org/proxy_u/de-en.en.9b4ab6fc-647fbce7-30195a51-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-Intune-und-Co-Vereinfache-Dein-Patchmanagement-mit-dem-Winget-Script-10k-SW-P


# Hier kannst du die Standardwerte für deine Parameter festlegen, falls du sie nicht per Parameter übergeben möchtest.
# $modus = "update"  # Oder ein anderer Modus, je nach Bedarf
# $id = "Jabra.Direct" # Die ID deines Pakets

Param(
    [Parameter(Mandatory=$false)]
    [string]$modus,

    [Parameter(Mandatory=$false)]
    [string]$id
)

# Überprüfung, ob der Modus-Parameter angegeben wurde
if (-not $modus) {
    Write-Error -Message "Fehler: Der Parameter 'modus' ist erforderlich und wurde nicht angegeben."
    exit 1
}

# PowerShell-Einstellungen
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Überprüfung, ob der id-Parameter für bestimmte Modi erforderlich und angegeben ist
if ($modus -notin @('UpdateAll') -and -not $id) {
    Write-Error -Message "Fehler: Der Parameter 'id' ist erforderlich für den Modus '$modus', wurde aber nicht angegeben."
    exit 1
}

# Assets
## Szenariospezifisch
$WingetPackageId = $id

# Funktionen
function CheckWinget {
    ## Finde winget-cli
    ### Verzeichnis finden
    $WingetDirectory = [string](
        $(
            if ([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18') {
                (Get-Item -Path ('{0}\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe' -f $env:ProgramW6432)).'FullName' | Select-Object -First 1                
            }
            else {
                '{0}\Microsoft\WindowsApps' -f $env:LOCALAPPDATA
            }
        )
    )
    ### Dateinamen finden
    $WingetCliFileName = [string](
        $(
            [string[]](
                'AppInstallerCLI.exe',
                'winget.exe'
            )
        ).Where{
            [System.IO.File]::Exists(
                ('{0}\{1}' -f $WingetDirectory, $_)
            )
        } | Select-Object -First 1
    )
    ### Verzeichnis und Dateinamen kombinieren
    $WingetCliPath = [string] '{0}\{1}' -f $WingetDirectory, $WingetCliFileName

    # Überprüfen, ob $WingetCli vorhanden ist
    if (-not [System.IO.File]::Exists($WingetCliPath)) {
        Write-Output -InputObject 'Winget wurde nicht gefunden.'
        Exit 1
    }

    # Winget-Ausgabe-Codierung korrigieren
    $null = cmd /c '' 
    $Global:OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

    return $WingetCliPath
}

function InstallPackage {
    param(
        [string]$WingetCliPath,
        [string]$WingetPackageId
    )

    # Überprüfen, ob das Paket bereits installiert ist
    $installedPackages = [string[]](cmd /c ('"{0}" list --silent --source winget --accept-source-agreements' -f $WingetCliPath))
    

    if ($WingetPackageId -in $installedPackages) {
        Write-Output -InputObject 'Das Paket ist bereits installiert. Die Installation kann nicht fortgesetzt werden.'
        exit 1
    } else {
        $WingetResult = [string[]](cmd /c ('"{0}" install --exact --id {1} --silent --source winget --accept-package-agreements --accept-source-agreements' -f $WingetCliPath, $WingetPackageId))
        $WingetResult
    }
}

function UpdateSinglePackage {
    param(
        [string]$WingetCliPath,
        [string]$WingetPackageId
    )

    # Überprüfen, ob das Paket installiert ist und ob ein Update verfügbar ist
    $WingetResult = [string[]](cmd /c ('"{0}" list --exact --id {1} --source winget --accept-source-agreements' -f $WingetCliPath, $WingetPackageId))
    
    if ($WingetResult[-1] -like ('*{0}*' -f $WingetPackageId) -and $WingetResult[-3] -like '*available*') {
        Write-Output -InputObject "Das Paket '$WingetPackageId' ist installiert und ein Update ist verfügbar. Es wird jetzt aktualisiert."
        $WingetUpdateResult = [string[]](cmd /c ('"{0}" update --exact --id {1} --silent --source winget --accept-package-agreements --accept-source-agreements' -f $WingetCliPath, $WingetPackageId))
        $WingetUpdateResult
    }
    elseif ($WingetResult[-1] -notlike ('*{0}*' -f $WingetPackageId)) {
        Write-Output -InputObject "Das Paket '$WingetPackageId' ist nicht installiert. Es wird jetzt installiert und anschließend aktualisiert."
        InstallPackage -WingetCliPath $WingetCliPath -WingetPackageId $WingetPackageId
        UpdateSinglePackage -WingetCliPath $WingetCliPath -WingetPackageId $WingetPackageId
    }
    else {
        Write-Output -InputObject "Das Paket '$WingetPackageId' ist installiert und es ist kein Update verfügbar."
        exit 0
    }
}

function UpdateAllPackages {
    param([string]$WingetCliPath)

    $WingetResult = [string[]](cmd /c ('"{0}" update --all --silent --source winget' -f $WingetCliPath))
    $WingetResult
}

function UninstallPackage {
    param(
        [string]$WingetCliPath,
        [string]$WingetPackageId
    )

    $WingetResult = [string[]](cmd /c ('"{0}" uninstall --exact --id {1} --silent --source winget' -f $WingetCliPath, $WingetPackageId))
    $WingetResult
}

# Winget überprüfen
$WingetCliPath = CheckWinget

# Modus ausführen
switch ($modus) {
    'Install' { InstallPackage -WingetCliPath $WingetCliPath -WingetPackageId $WingetPackageId }
    'Update' { UpdateSinglePackage -WingetCliPath $WingetCliPath -WingetPackageId $WingetPackageId }
    'UpdateAll' { UpdateAllPackages -WingetCliPath $WingetCliPath }
    'Deinstallation' { UninstallPackage -WingetCliPath $WingetCliPath -WingetPackageId $WingetPackageId }
}
