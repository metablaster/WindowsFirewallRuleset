
# Import global variables
Import-Module "$PSScriptRoot\..\..\Modules\GlobalVariables.psm1"

# Setup local variables:
$Group = "Browser"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Internet browser rules
#

# Google Chrome
New-NetFirewallRule -Whatif:$Deubg -ErrorAction Continue -Platform $Platform `
-DisplayName "Google Chrome HTTP" -Program "%LocalAppData%\Google\Chrome\Application\chrome.exe" `
-PolicyStore $PolicyStore -Enabled True -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort 80 `
-Description "HTTP access"
