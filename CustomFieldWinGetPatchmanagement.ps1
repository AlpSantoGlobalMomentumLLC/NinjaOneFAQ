# NinjaOne RMM Custom Felder für das Winget Patchmanagement / NinjaOne RMM Custom fields for the Winget patch management
# Work in Progress: On some PCs false Syntax Errors
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-Custom-Felder-fur-das-Winget-Patchmanagement
# https://translated.turbopages.org/proxy_u/de-en.en.d4112092-647fbbf6-96e6bd9b-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-Custom-Felder-fur-das-Winget-Patchmanagement


# Define the functions
function Get-WingetOutput {
    $WingetCliPath = CheckWinget
    $WingetResult = [string[]](cmd /c ('"{0}" upgrade --accept-source-agreements --include-unknown' -f $WingetCliPath))
    return $WingetResult
}


function Install-Winget {
    function getNewestLink($match) {
	    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	    $get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
	    $data = $get[0].assets | Where-Object name -Match $match
	    return $data.browser_download_url
    }

    $wingetUrl = getNewestLink("msixbundle")
    $wingetLicenseUrl = getNewestLink("License1.xml")

    function section($text) {
	    Write-Output "###################################"
	    Write-Output "# $text"
	    Write-Output "###################################"
    }

    function AAP($pkg) {
	    Add-AppxPackage $pkg -ErrorAction SilentlyContinue
    }

    section("Downloading Xaml nupkg file... (19000000ish bytes)")
    $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.1"
    $nupkgFolder = "Microsoft.UI.Xaml.2.7.1.nupkg"
    $zipFile = "Microsoft.UI.Xaml.2.7.1.nupkg.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipFile
    section("Extracting appx file from nupkg file...")
    Expand-Archive $zipFile

    if ([Environment]::Is64BitOperatingSystem) {
	    section("64-bit OS detected")
	    AAP("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx")
	    AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx")
    } else {
	    section("32-bit OS detected")
	    AAP("https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx")
	    AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x86\Release\Microsoft.UI.Xaml.2.7.appx")
    }

    section("Downloading winget... (21000000ish bytes)")
    $wingetPath = "winget.msixbundle"
    Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath
    $wingetLicensePath = "license1.xml"
    Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath
    section("Installing winget...")
    Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction SilentlyContinue

    <#section("Adding WindowsApps directory to PATH variable for current user...")
    $path = [Environment]::GetEnvironmentVariable("PATH", "User")
    $path = $path + ";" + [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
    [Environment]::SetEnvironmentVariable("PATH", $path, "User")#>
    
    section("Adding WindowsApps directory to PATH variable for all users...")
    $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $path = $path + ";" + [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
    [Environment]::SetEnvironmentVariable("PATH", $path, "Machine")


    section("Cleaning up...")
    Remove-Item $zipFile
    Remove-Item $nupkgFolder -Recurse
    Remove-Item $wingetPath
    Remove-Item $wingetLicensePath

    section("Installation complete!")
    section("Please restart your computer to complete the installation.")
}


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
    $WingetCliFileName = [string](SourceAgreementsMarketMessage
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
        ##Write-Output -InputObject 'Winget wurde nicht gefunden.'
        ##Exit 1
        Install-Winget
        
    }

    # Winget-Ausgabe-Codierung korrigieren
    $null = cmd /c '' 
    $Global:OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

    return $WingetCliPath
}

function Filter-Lines ($output, $keywords) {
    $filteredLines = @()
    $lines = $output -split "`n"
    foreach($line in $lines){
        $containsKeyword = $false
        foreach($keyword in $keywords){
            if($line -match $keyword){
                $containsKeyword = $true
                break
            }
        }
        if(-not $containsKeyword){
            $filteredLines += $line
        }
    }
    return $filteredLines
}

function Remove-Line ($output, $lineContent) {
    $lines = $output -split "`n"
    $cleanedOutput = @($lines | Where-Object { -not ($_ -match $lineContent) })
    return $cleanedOutput -join "`n"
}

function Extract-UpdateCount ($output) {
    $lines = $output -split "`n"
    # $updateLines = @($lines | Where-Object { $_ -match "winget" })
    $updateLines = @($lines | Where-Object { $_ -match "winget|msstore" })

    return $updateLines.Count
}


# Use the functions
$output = Get-WingetOutput
$filteredLines = Filter-Lines $output @('Microsoft', 'Mindestens ein Paket', 'Aktualisierungen', '   -\\| ')
$filteredLines = Filter-Lines $output @('Microsoft', 'Firefox', 'Mindestens ein Paket', 'Aktualisierungen', '   -\\| ')
$filteredLines = Remove-Line $filteredLines "2 upgrades available."
$filteredLines = Remove-Line $filteredLines " KB /"
$filteredLines = Remove-Line $filteredLines " MB /"
$filteredLines = Remove-Line $filteredLines "SourceAgreementsTitle"
$filteredLines = Remove-Line $filteredLines "SourceAgreementsMarketMessage"


$updateCount = Extract-UpdateCount $filteredLines

# Print the results
Write-Output "Filtered Lines:"
Write-Output $filteredLines
Write-Output "Update Count: $updateCount"

# Gib Resultate an NinjaOne
Ninja-Property-Set wingetVerfuegbareUpdatesListe $filteredLines | Out-Null
Ninja-Property-Set wingetVerfuegbareUpdates $updateCount | Out-Null
    
