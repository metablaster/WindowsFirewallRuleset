
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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

<#
.SYNOPSIS
Outbound firewall rules for non essential networking

.DESCRIPTION
Windows Firewall predefined rules related to networking not handled by other more strict scripts
The following predefined groups are included:
1. AllJoin Router
2. Cast to device functionality
3. Connected devices platform

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\AdditionalNetworking.ps1

.INPUTS
None. You cannot pipe objects to AdditionalNetworking.ps1

.OUTPUTS
None. AdditionalNetworking.ps1 does not generate any output

.NOTES
NOTE: There are no predefined outbound rules for connections to "DIAL protocol server"
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Additional Networking"
$Accept = "Outbound rules for additional networking will be loaded, recommended for specific scenarios"
$Deny = "Skip operation, outbound additional networking rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues = @{
	"Test-ExecutableFile:Quiet" = $Quiet
	"Test-ExecutableFile:Force" = $Trusted -or $SkipSignatureCheck
	"Test-ExecutableFile:Session" = $SessionInstance
}
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

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
	-InterfaceType $DefaultInterface `
	-Description "Outbound rule for the Cast to Device functionality to allow use of the
Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV)
streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS)
for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement,
application feedback, and traffic prioritization." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Cast to Device functionality (qWave)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service QWAVE -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress PlayToDevice4 `
	-LocalPort Any -RemotePort 2177 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for the Cast to Device functionality to allow use of the
	Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV)
streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS)
for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement,
application feedback, and traffic prioritization." |
Format-RuleOutput

$Program = "%SystemRoot%\System32\mdeserver.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress PlayToDevice4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." |
	Format-RuleOutput

	New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress LocalSubnet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." |
	Format-RuleOutput

	New-NetFirewallRule -DisplayName "Cast to Device streaming server (RTP)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." |
	Format-RuleOutput
}

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
	-InterfaceType $DefaultInterface `
	-Description "Outbound rule to use Wi-Fi Direct traffic in the Connected Devices Platform." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Connected Devices Platform" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service CDPSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Outbound rule for Connected Devices Platform traffic." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Connected Devices Platform" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service CDPSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for Connected Devices Platform traffic." |
Format-RuleOutput

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
	-InterfaceType $DefaultInterface `
	-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be
unable to run." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "AllJoyn Router" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service AJRouter -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be
unable to run." |
Format-RuleOutput

#
# Proximity sharing predefined rule
#
$ServerTarget = (Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
		-ClassName Win32_OperatingSystem -EA Stop |
	Select-Object -ExpandProperty ProductType) -eq 3

if (!$ServerTarget)
{
	# NOTE: does not exist in Windows Server 2019 and 2022
	# TODO: description missing data
	$Program = "%SystemRoot%\System32\ProximityUxHost.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Proximity sharing" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-Description "Outbound rule for Proximity sharing over." |
		Format-RuleOutput
	}
}

#
# Router access
#

New-NetFirewallRule -DisplayName "Router configuration (HTTP/S)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DefaultGateway `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterface `
	-Description "Allow router configuration trough browser" |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log
