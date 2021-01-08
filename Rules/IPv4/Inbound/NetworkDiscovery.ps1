
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Inbound network discovery rules

.DESCRIPTION
Network Discovery predefined rules + additional rules
Rules which apply to network discovery on LAN

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\NetworkDiscovery.ps1

.INPUTS
None. You cannot pipe objects to NetworkDiscovery.ps1

.OUTPUTS
None. NetworkDiscovery.ps1 does not generate any output

.NOTES
HACK: Due to some magic with predefines rules these rules here don't work for home network setup (WORKGROUP)
Same applies to "File and printer sharing" predefined rules
NOTE: Current workaround for home networks is to apply predefined "Network Discovery" rules into GPO.
TODO: Intranet4 and Intranet4 removed IPv4 restriction to troubleshoot homegroup
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "@FirewallAPI.dll,-32752"
$DisplayGroup = "Network Discovery"
$LocalProfile = "Private, Domain"
$Accept = "Inbound rules for network discovery will be loaded, required for host discovery in local networks"
$Deny = "Skip operation, inbound network discovery rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $DisplayGroup
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $Group -Direction $Direction -NewPolicyStore $PolicyStore

Get-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction | ForEach-Object {
	$_ | Format-Output -Modify
	[hashtable] $Params = @{
		InputObject = $_
		Enabled = "True"
		LocalUser = "Any"
		# NOTE: Requires allowing loopback and multicast elsewhere
		InterfaceType = $DefaultInterface
	}

	if ($_.Profile -eq "Domain")
	{
		$Params["Enabled"] = "False"
	}

	if ((Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_).Program -eq "System")
	{
		$Params["LocalUser"] = $LocalSystem
	}

	Set-NetFirewallRule @Params
}

# NOTE: Following rules are no longer relevant
return

#
# Network Discovery predefined rules + additional rules
# TODO: separate custom rules with comment
#

New-NetFirewallRule -DisplayName "Link Local Multicast Name Resolution" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5355 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow Link Local Multicast Name Resolution.
The DNS Client service (dnscache) caches Domain Name System (DNS) names and registers the full
computer name for this computer.
If the rule is disabled, DNS names will continue to be resolved.
However, the results of DNS name queries will not be cached and the computer's name will not be
registered." | Format-Output

New-NetFirewallRule -DisplayName "Link Local Multicast Name Resolution" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5355 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow Link Local Multicast Name Resolution.
The DNS Client service (dnscache) caches Domain Name System (DNS) names and registers the full
computer name for this computer.
If the rule is disabled, DNS names will continue to be resolved.
However, the results of DNS name queries will not be cached and the computer's name will not be
registered." | Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Datagram" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 138 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." |
Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Datagram" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 138 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." |
Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Datagram" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 138 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." |
Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 137 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." |
Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 137 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." |
Format-Output

New-NetFirewallRule -DisplayName "NetBIOS Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 137 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." |
Format-Output

New-NetFirewallRule -DisplayName "WSD (FDResPub)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service FDResPub -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
Publishes this computer and resources attached to this computer so they can be discovered over the network.
If this rule is disabled, network resources will no longer be published and they will not be
discovered by other computers on the network." |
Format-Output

New-NetFirewallRule -DisplayName "WSD (FDResPub)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service FDResPub -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
Publishes this computer and resources attached to this computer so they can be discovered over the network.
If this rule is disabled, network resources will no longer be published and they will not be
discovered by other computers on the network." |
Format-Output

New-NetFirewallRule -DisplayName "SSDP Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 1900 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol.
Service discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is disabled, SSDP-based devices will not be discovered." |
Format-Output

New-NetFirewallRule -DisplayName "SSDP Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 1900 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol.
Service discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is disabled, SSDP-based devices will not be discovered." |
Format-Output

New-NetFirewallRule -DisplayName "UPnP Device Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 2869 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted
devices can be added." |
Format-Output

New-NetFirewallRule -DisplayName "UPnP Device Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 2869 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted
devices can be added." |
Format-Output

New-NetFirewallRule -DisplayName "UPnP Device Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 2869 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted
devices can be added." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5357 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 5357 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5357 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5358 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 5358 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD Events Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5358 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD (FDPHost)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD (FDPHost)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery." |
Format-Output

New-NetFirewallRule -DisplayName "WSD (Device Association Framework Provider Host)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program "%SystemRoot%\System32\dasHost.exe" -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalService -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" |
Format-Output

New-NetFirewallRule -DisplayName "WSD (Device Association Framework Provider Host)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program "%SystemRoot%\System32\dasHost.exe" -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 3702 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalService -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" |
Format-Output

New-NetFirewallRule -DisplayName "Teredo SSDP Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol." |
Format-Output

New-NetFirewallRule -DisplayName "Teredo UPnP Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol." |
Format-Output

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
