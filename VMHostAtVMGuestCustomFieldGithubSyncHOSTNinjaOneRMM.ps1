# NinjaOne RMM: VM-Hosts auf dem VM-Client anzeigen m. Github sync. / NinjaOne RMM: VM-host-to-VM view Client from m. Github sync.
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-VM-Hosts-auf-dem-VM-Client-anzeigen
# https://translated.turbopages.org/proxy_u/de-en.en.46aa5c51-647fb980-da8ff9b8-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-VM-Hosts-auf-dem-VM-Client-anzeigen


#### HOST
# Made for not only for NinjaOne

# Axel Christian Lenz 
# https://www.linkedin.com/in/axellenz/

################## ANPASSEN!!!##############################
$global:pat = ""
$global:owner = ""

# Dies ist eine Funktion, die alle VMs auf einem Hyper-V-Host erfasst.
function GetVMInventory {
    # "Get-VM" ist ein PowerShell-Cmdlet, das alle VMs auf dem Host auflistet.Write Guest VMs to the Host field
    # Wir müssen sicherstellen, dass diese Funktion auf dem Hyper-V-Host ausgeführt wird.
    $VMs = Get-VM
    return $VMs
}

function WriteGitHubFile($repo, $path, $content) {
    $base64Content = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $body = @{
        "message" = "update $path"
        "committer" = @{
            "name" = $owner
            "email" = "your@email.com"
        }
        "content" = $base64Content
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Method Put -Uri "https://api.github.com/repos/$owner/$repo/contents/$path" -Headers @{Authorization = "token $pat"} -Body $body
    } catch {
        Write-Host "An error occurred: $_"
    }
}


# Dies ist eine Funktion, die die VM-Inventarliste in eine Textdatei auf einem Netzlaufwerk schreibt.
function WriteInventoryToNDrive {
    param($VMs)
    $path = "\\XXXSRVFS01\Austausch\NinjaOne\Scripting\SRVVMHOST\$($env:COMPUTERNAME).txt"
    if (Test-Path $path) {
        Remove-Item $path
    }
    foreach ($VM in $VMs) {
        Add-Content -Path $path -Value $VM.Name
    }
}



function WriteInventoryToGithub {
    param($VMs)
        $repo = "NinjaScriptingStore"
################## ANPASSEN!!! #######################################
    $path = "LZR/SRVVMHOSTInventory/$($env:COMPUTERNAME).txt"

    $content = ""
    foreach ($VM in $VMs) {
        $content += "$($VM.Name)`n"
    }

    WriteGitHubFile -repo $repo -path $path -content $content
}




function WriteToNinjaOne {
    param($VMs)
    $fieldValue = ($VMs | ForEach-Object { $_.Name }) -join ', '
    # Kombiniert die VM-Namen zu einer einzigen Zeichenkette, getrennt durch Kommas.
    Ninja-Property-Set VMs $fieldValue
}


<#
# Dies ist eine Funktion, die die VM-Liste als Wert an ein NinjaOne-Eigenschaftsfeld übergibt.
function WriteToNinjaOne {
    param($VMs)
    $fieldValue = $VMs -join ', '  # Kombiniert die VM-Namen zu einer einzigen Zeichenkette, getrennt durch Kommas.
    Ninja-Property-Set VMs $fieldValue
}#>

# Dies ist eine Funktion, die die Ausgabe auf der Konsole anzeigt.
function WriteToConsole {
    param($VMs)
    foreach ($VM in $VMs) {
        Write-Output $VM.Name
    }
}

# Hier verbinden wir die Funktionen und übergeben die Informationen.
$VMs = GetVMInventory
# WriteInventoryToNDrive -VMs $VMs
WriteInventoryToGithub -VMs $VMs
WriteToNinjaOne -VMs $VMs
WriteToConsole -VMs $VMs
