# NinjaOne RMM: VM-Hosts auf dem VM-Client anzeigen m. Github sync. / NinjaOne RMM: VM-host-to-VM view Client from m. Github sync.
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-VM-Hosts-auf-dem-VM-Client-anzeigen
# https://translated.turbopages.org/proxy_u/de-en.en.46aa5c51-647fb980-da8ff9b8-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-VM-Hosts-auf-dem-VM-Client-anzeigen

# Made for not only for NinjaOne

# Axel Christian Lenz 
# https://www.linkedin.com/in/axellenz/



################## ANPASSEN!!!
$pat = ""

$owner = ""
$repo = "NinjaScriptingStore"
$folder = ""


function ReadGitHubFile($repo, $path, $pat) {
    $uri = "https://api.github.com/repos/$owner/$repo/contents/$path"
    $headers = @{Authorization = "token $pat"}
    
    $base64Content = Invoke-RestMethod -Uri $uri -Headers $headers | Select-Object -ExpandProperty content
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))
}

function ReadAllFilesInGitHubFolder($repo, $folder, $pat) {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/contents/$folder" -Headers @{Authorization = "token $pat"}
    $fileNames = $response | Where-Object { $_.type -eq "file" -and $_.name -like "*.txt" } | ForEach-Object { $_.path }
    
    $fileContents = @()

    foreach ($filePath in $fileNames) {
        $content = ReadGitHubFile $repo $filePath $pat
        $lines = $content -split "`n" | Where-Object { $_ -ne "" }
        $fileName = ($filePath -split "/")[-1] -replace ".txt", ""
        
        foreach ($line in $lines) {
            $fileContents += "$fileName,$line"
        }
    }

    return $fileContents
}



# Diese Funktion ermittelt den Hostnamen der lokalen Maschine und sucht ihn in den Dateiinhalten.
function SearchVMHost {
    param($fileContents)
    $localHostName = $env:COMPUTERNAME
    foreach ($line in $fileContents) {
        if ($line -match $localHostName) {
            return $line.Split(",")[0]
        }
    }
    return $null
}

# Diese Funktion schreibt die VM-Host-Information in ein NinjaOne-Eigenschaftsfeld.
function WriteToNinjaOne {
    param($vmHost)
    Ninja-Property-Set vmHost $vmHost
}

# Hier verwenden wir die Funktionen und geben die Ergebnisse aus.
# $fileContents = ReadAllFiles

# $result = ReadAllFilesInGitHubFolder $repo $folder $pat
# $result
$fileContents = ReadAllFilesInGitHubFolder $repo $folder $pat

#$fileContents = ReadAllFilesFromGithub
$vmHost = SearchVMHost -fileContents $fileContents
WriteToNinjaOne -vmHost $vmHost

if ($vmHost) {
    Write-Output "The VM host for this machine is: $vmHost"
} else {
    Write-Output "This machine's host could not be found in the VM inventory."
}
