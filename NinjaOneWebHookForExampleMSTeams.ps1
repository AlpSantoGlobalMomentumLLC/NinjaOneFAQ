# PowerShell trifft auf Microsoft Teams: WebHooks für NinjaOne RMM und mehr
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# ninjaonefaq.dcms.site
# Beschreibung: https://ninjaonefaq.dcms.site/post/PowerShell-trifft-auf-Microsoft-Teams-WebHooks-fur-NinjaOne-RMM-und-mehr
# Description AutoTranslated: https://translated.turbopages.org/proxy_u/de-en.en.09430a0b-647fb4d5-b56b6ae2-74722d776562/https/ninjaonefaq.dcms.site/post/PowerShell-trifft-auf-Microsoft-Teams-WebHooks-fur-NinjaOne-RMM-und-mehr


# Parametereingabe
param (
    [Parameter(Mandatory = $true)]
    [string]$T,

    [Parameter(Mandatory = $true)]
    [string]$M
)

# Variablen
$webhookUrl = "https://xxxxxxx.webhook.office.com/webhookb2/xxxxxxxxb780601c7f69/IncomingWebhook/xxxxx"
$hostname = $env:COMPUTERNAME
$dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Nachricht formatieren
$formattedMessage = @"
#### `#$T`   
Message: $M  
Host: $hostname   
Date/Time: $dateTime   
"@

# Nachricht als JSON formatieren
$messagePayload = @{
    text = $formattedMessage
} | ConvertTo-Json

# Nachricht an Microsoft Teams senden
Invoke-RestMethod -Method Post -Uri $webhookUrl -Body $messagePayload -ContentType "application/json"
