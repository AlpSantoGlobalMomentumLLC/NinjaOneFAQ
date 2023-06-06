# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-Nie-wieder-ein-auslaufendes-Zertifikat-vergessen
# https://translated.turbopages.org/proxy_u/de-en.en.c04c0c32-647fb87b-24016ea1-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-Nie-wieder-ein-auslaufendes-Zertifikat-vergessen

param(
    [int]$daysToExpire = 30, # Standardzahl der Tage, bis das Zertifikat abläuft
    [int]$expiredDaysLimit = 30 # Standardzahl der Tage, seit das Zertifikat abgelaufen ist
)

# Definiere die Zertifikatsspeicher, die überprüft werden sollen
$certificateStores = @("My", "Root", "CA")

# Funktion zur Überprüfung des Ablaufdatums des Zertifikats
function Check-CertificateExpiration {
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [int]$DaysToExpire,
        [int]$ExpiredDaysLimit
    )

    # Konvertiere die Datumsangaben in ein universelles Format (UTC), um Inkonsistenzen in den Zeitzonen zu vermeiden
    $currentDate = (Get-Date).ToUniversalTime()
    $expirationDate = $Certificate.NotAfter.ToUniversalTime()
    
    # Berechne die verbleibenden Tage
    $daysRemaining = ($expirationDate - $currentDate).Days

    return ($daysRemaining -le $DaysToExpire -and $daysRemaining -ge -$ExpiredDaysLimit)
}

# Funktion zur Extrahierung des CN aus dem Subject des Zertifikats
function Get-CertificateCN {
    param(
        [string]$Subject
    )
    return (($Subject -split ',')[0] -split '=')[1]
}

# Hole die Zertifikate aus den angegebenen Speichern
$certificates = @()
foreach ($store in $certificateStores) {
    $certificates += Get-ChildItem -Path "Cert:\LocalMachine\$store"
}

$ReasonOutput = ""
$expiredFound = $false

# Überprüfe jedes Zertifikat auf Ablaufdatum
foreach ($certificate in $certificates) {
    $certificateCN = Get-CertificateCN -Subject $certificate.Subject
    # Write-Output "Überprüfe Zertifikat: '$certificateCN', Ablaufdatum: '$($certificate.NotAfter)'"
    if (Check-CertificateExpiration -Certificate $certificate -DaysToExpire $daysToExpire -ExpiredDaysLimit $expiredDaysLimit) {
        $expiredFound = $true
        $ReasonOutput += "Zertifikat '$certificateCN' laeuft ab oder ist bereits abgelaufen. Ablaufdatum: '$($certificate.NotAfter)'" + "`n"
        Write-Output "Zertifikat '$certificateCN' laeuft ab oder ist bereits abgelaufen. Ablaufdatum: '$($certificate.NotAfter)'"
    }
}

if ($expiredFound) {
    # Füge hier den Befehl ein, um die Ausgabe in NinjaOne zu schreiben
    Ninja-Property-Set auslaufendeZertifikate $ReasonOutput | Out-Null
    exit 2
} else {
    # Füge hier den Befehl ein, um das NinjaOne-Feld zu leeren
    Ninja-Property-Set auslaufendeZertifikate '' | Out-Null
    Write-Output "OK"
}
