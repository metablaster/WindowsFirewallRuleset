
# Import global variables
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Setup local variables:
$Group = "Windows System"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Windows system predefined rules for Wireless Display
#

# TODO: local user may need to be 'Any', needs testing.
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Wireless Display" -Service Any -Program "%SystemRoot%\System32\WUDFHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $NT_AUTHORITY_UserModeDrivers `
-Description "Driver Foundation - User-mode Driver Framework Host Process.
The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs."

# TODO: remote port unknown, rule added because predefined rule for UDP exists
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Wireless Display" -Service Any -Program "%SystemRoot%\System32\WUDFHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_UserModeDrivers `
-Description "Driver Foundation - User-mode Driver Framework Host Process.
The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs."
