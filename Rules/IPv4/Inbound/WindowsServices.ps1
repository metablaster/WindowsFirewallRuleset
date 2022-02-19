
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
Inbound firewall rules forfirewall rules for Windows services

.DESCRIPTION
Windows services rules
Rules which apply to Windows services which are not handled by predefined rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\WindowsServices.ps1

.INPUTS
None. You cannot pipe objects to WindowsServices.ps1

.OUTPUTS
None. WindowsServices.ps1 does not generate any output

.NOTES
None.
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
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Windows Services"
$Accept = "Inbound rules for system services will be loaded, required for proper functioning of operating system"
$Deny = "Skip operation, inbound rules for system services will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for delivery optimization
#
# Delivery Optimization listens on port 7680 for requests from other peers by using TCP/IP.
# The service will register and open this port on the device, but you might need to set this port
# to accept inbound traffic through your firewall yourself.
# If you don't allow inbound traffic over port 7680, you can't use the peer-to-peer functionality
# of Delivery Optimization.
# However, devices can still successfully download by using HTTP or HTTPS traffic over port 80
# (such as for default Windows Update data).
#
# TODO: If you set up Delivery Optimization to create peer groups that include devices across NATs
# (or any form of internal subnet that uses gateways or firewalls between subnets), it will use Teredo.
# For this to work, you must allow inbound TCP/IP traffic over port 3544.
# Look for a "NAT traversal" setting in your firewall to set this up.
#
# Delivery Optimization also communicates with its cloud service by using HTTP/HTTPS over port 80.
#

# TODO: for testing purposes -RemoteAddress is Any instead of LocalSubnet4
New-NetFirewallRule -DisplayName "Delivery Optimization" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service DoSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 7680 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Allow `
	-InterfaceType $DefaultInterface `
	-Description "Delivery optimization clients connect to peers on port 7680" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Delivery Optimization" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service DoSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 7680 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Allow `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Delivery optimization clients connect to peers on port 7680" |
Format-RuleOutput

#
# @FirewallAPI.dll,-80204 predefined rule
#

New-NetFirewallRule -DisplayName "Windows Camera Frame Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service FrameServer -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 554, 8554-8558 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Service enables multiple clients to access video frames from camera devices." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Windows Camera Frame Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service FrameServer -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 5000-5020 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Service enables multiple clients to access video frames from camera devices." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
