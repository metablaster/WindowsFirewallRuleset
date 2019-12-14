
#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

#
# Setup local variables:
#
$Group = "Internet Browser"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$ChromeRoot = "%LocalAppData%\Google\Chrome\Application"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Internet browser rules
#

# Google Chrome
New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome HTTP" -Service Any -Program "$ChromeRoot\chrome.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser $User `
-Description "HTTP access"
