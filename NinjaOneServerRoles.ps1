# NinjaOne RMM: Gekonnt erweitert um die Windows Server Rollen / NinjaOne RMM: Skillfully added to the Windows Server roles
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# https://ninjaonefaq.dcms.site/post/NinjaOne-RMM-Gekonnt-erweitert-um-die-Windows-Server-Rollen
# https://translated.turbopages.org/proxy_u/de-en.en.9baf5773-647fbb2c-d3fa80c7-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-RMM-Gekonnt-erweitert-um-die-Windows-Server-Rollen

Ninja-Property-Set serverRollen (Get-WindowsFeature | Where-Object {$_.InstallState -eq 'Installed' -and $_.Parent -eq $null} | Select-Object -ExpandProperty Name) -join ' - '
