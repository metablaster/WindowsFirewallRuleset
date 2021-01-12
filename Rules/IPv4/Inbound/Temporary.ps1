
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
Temporary inbound firewall rules

.DESCRIPTION
Temporary rules are enabled on demand only to let some program do it's internet work, or
to troubleshoot firewall without shuting it down completely.

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\Temporary.ps1

.INPUTS
None. You cannot pipe objects to Temporary.ps1

.OUTPUTS
None. Temporary.ps1 does not generate any output

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
$Group = "Temporary - IPv4"
$Accept = "Temporary inbound IPv4 rules will be loaded, recommended to temporarily enable specific IPv4 traffic"
$Deny = "Skip operation, temporary inbound IPv4 rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

if ($Develop)
{
	#
	# Troubleshooting rules
	# TODO: Some troubleshotting rules apply to both IPv4 and IPv6
	# This traffic fails mostly with virtual adapters, it's not covered by regular rules
	#

	# Accounts used for troubleshooting rules
	# $TroubleshootingAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE"

	# NOTE: local address should include multicast
	# NOTE: traffic can come from router
	New-NetFirewallRule -DisplayName "Troubleshoot UDP ports" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort 1900, 3702 -RemotePort Any `
		-LocalUser $LocalService -EdgeTraversalPolicy Block `
		-InterfaceType Any `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Temporary allow troublesome UDP traffic." |
	Format-RuleOutput

	$mDnsUsers = Get-SDDL -Domain "NT AUTHORITY" -User "NETWORK SERVICE"
	Merge-SDDL ([ref] $mDnsUsers) -From $UsersGroupSDDL

	# NOTE: should be network service
	New-NetFirewallRule -DisplayName "Troubleshoot UDP - mDNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $ClassB, $ClassC -RemoteAddress Any `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser $mDnsUsers -EdgeTraversalPolicy Block `
		-InterfaceType Any `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Temporary allow troublesome UDP traffic." |
	Format-RuleOutput

	# HACK: Inbound rule with "-LooseSourceMapping $true" cant be created:
	# Invalid flags specified.
	New-NetFirewallRule -DisplayName "Troubleshoot UDP LocalOnlyMapping" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType Any `
		-LocalOnlyMapping $true -LooseSourceMapping $false `
		-Description "Temporary allow all UDP with LocalOnlyMapping" |
	Format-RuleOutput

	if ($UpdateGPO)
	{
		Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	}

	Update-Log
}
