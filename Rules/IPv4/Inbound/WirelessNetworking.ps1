
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Wireless Networking"
$WNInterface = "Wireless"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Windows system predefined rules for Wireless Display
#

$Program = "%SystemRoot%\System32\WUDFHost.exe"
Test-File $Program @Logs

# TODO: local user may need to be 'Any', needs testing.
New-NetFirewallRule -Platform $Platform `
-DisplayName "Wireless Display" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $WNInterface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 443 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_UserModeDrivers `
-Description "Driver Foundation - User-mode Driver Framework Host Process.
The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs." @Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\CastSrv.exe"
Test-File $Program @Logs

# TODO: remote port unknown, rule added because predefined rule for UDP exists
New-NetFirewallRule -Platform $Platform `
-DisplayName "Wireless Display Infrastructure back channel" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $WNInterface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 7250 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Miracast is a Wi-Fi display certification program announced by Wi-Fi Alliance for seamlessly displaying video between devices.
Users attempt to connect to a Miracast receiver as they did previously.
When the list of Miracast receivers is populated, Windows 10 will identify that the receiver is capable of supporting a connection over the infrastructure.
When the user selects a Miracast receiver, Windows 10 will attempt to resolve the device's hostname via standard DNS, as well as via multicast DNS (mDNS).
If the name is not resolvable via either DNS method, Windows 10 will fall back to establishing the Miracast session using the standard Wi-Fi direct connection." @Logs | Format-Output @Logs

#
# Windows system predefined rules for WiFi Direct
#

# NOTE: WlanSvc not enable by default in Windows Server 2019
New-NetFirewallRule -Platform $Platform `
-DisplayName "WLAN Service WFD ASP Coordination Protocol" -Service WlanSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $WNInterface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 7325 -RemotePort 7325 `
-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "WLAN Service to allow coordination protocol for WFD Service sessions.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that are running the same application
to establish a direct connection without requiring an intermediary, such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "WLAN Service WFD Driver-only" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $WNInterface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "Rule for drivers to communicate over WFD, WFD Services kernel mode driver rule.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that are running the same application
to establish a direct connection without requiring an intermediary, such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "WLAN Service WFD Driver-only" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $WNInterface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for drivers to communicate over WFD, WFD Services kernel mode driver rule.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that are running the same application
to establish a direct connection without requiring an intermediary, such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." @Logs | Format-Output @Logs

#
# Windows system predefined rules for WiFi Direct Network Discovery
#

$Program = "%SystemRoot%\System32\dasHost.exe"
Test-File $Program @Logs

# TODO: missing protocol and port for WiFi Direct Network Discovery
New-NetFirewallRule -Platform $Platform `
-DisplayName "Wi-Fi Direct Network Discovery" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType Wired, Wireless `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LocalService `
-Description "Rule to discover WSD devices on Wi-Fi Direct networks.
Host enables pairing between the system and wired or wireless devices. This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Wi-Fi Direct Scan Service" -Service stisvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType Wired, Wireless `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Rule to use WSD scanners on Wi-Fi Direct networks.
Windows Image Acquisition (WIA) service provides image acquisition services for scanners and cameras." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Wi-Fi Direct Spooler Use" -Service Spooler -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType Wired, Wireless `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Rule to use WSD printers on Wi-Fi Direct networks.
Print Spooler service spools print jobs and handles interaction with the printer.
If you turn off this service, you won't be able to print or see your printers." @Logs | Format-Output @Logs

#
# Windows system predefined rules for Wireless portable devices
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Wireless portable devices (SSDP)" -Service SSDPSRV -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Any -InterfaceType $WNInterface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 1900 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Wireless Portable Devices to allow use of the Simple Service Discovery Protocol." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Wireless portable devices (UPnP)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Any -InterfaceType $WNInterface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 2869 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "Wireless Portable Devices to allow use of Universal Plug and Play." @Logs | Format-Output @Logs

Update-Logs
