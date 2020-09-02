
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# Setup local variables
$Group = "Additional Networking"
$Accept = "Outbound rules for additional networking will be loaded, recommended for specific scenarios"
$Deny = "Skip operation, outbound additional networking rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Firewall predefined rules related to networking not handled by other more strict scripts
#

#
# Cast to device predefined rules
#

New-NetFirewallRule -DisplayName "Cast to Device functionality (qWave)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service QWAVE -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress PlayToDevice4 `
	-LocalPort Any -RemotePort 2177 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Outbound rule for the Cast to Device functionality to allow use of the
Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV)
streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS)
for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement,
application feedback, and traffic prioritization." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Cast to Device functionality (qWave)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service QWAVE -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress PlayToDevice4 `
	-LocalPort Any -RemotePort 2177 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for the Cast to Device functionality to allow use of the
	Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV)
streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS)
for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement,
application feedback, and traffic prioritization." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\mdeserver.exe"
Test-File $Program @Logs
New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress PlayToDevice4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." `
	@Logs | Format-Output @Logs

#
# Connected devices platform predefined rules
#

New-NetFirewallRule -DisplayName "Connected Devices Platform - Wi-Fi Direct Transport" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service CDPSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Outbound rule to use Wi-Fi Direct traffic in the Connected Devices Platform." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Connected Devices Platform" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service CDPSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Outbound rule for Connected Devices Platform traffic." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Connected Devices Platform" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service CDPSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for Connected Devices Platform traffic." `
	@Logs | Format-Output @Logs

#
# AllJoyn Router predefined rules
#

New-NetFirewallRule -DisplayName "AllJoyn Router" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service AJRouter -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be
unable to run." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "AllJoyn Router" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service AJRouter -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be
unable to run." `
	@Logs | Format-Output @Logs

#
# Proximity sharing predefined rule
#

# TODO: does not exist in Windows Server 2019
# TODO: description missing data
$Program = "%SystemRoot%\System32\ProximityUxHost.exe"
Test-File $Program @Logs
New-NetFirewallRule -DisplayName "Proximity sharing" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Outbound rule for Proximity sharing over." `
	@Logs | Format-Output @Logs

Update-Log
