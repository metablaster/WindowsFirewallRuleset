
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

<#
.SYNOPSIS
Outbound rules for

.DESCRIPTION

.EXAMPLE
PS> .\OutboundRule.ps1

.INPUTS
None. You cannot pipe objects to OutboundRule.ps1

.OUTPUTS
None. OutboundRule.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Temporary - IPv6"
$Accept = "Temporary outbound IPv6 rules will be loaded, recommended to temporarily enable specific IPv6 traffic"
$Deny = "Skip operation, temporary outbound IPv6 rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Temporary rules are enable on demand only to let some program do it's internet work, or
# to troubleshoot firewall without shuting it down completely.
#

# TODO: Assign IPv6 addresses to rules

if ($Develop)
{
	#
	# Troubleshooting rules
	# This traffic fails mostly with virtual adapters, it's not covered by regular rules
	#

	# Accounts used for troubleshooting rules
	# $TroubleshootingAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE" @Logs

	New-NetFirewallRule -DisplayName "Services" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service "*" -Program $ServiceHost -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $LinkScopedUnicast -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType Any `
		-Description "Enable only to let any service communicate on link local,
useful for troubleshooting, and disable ASAP." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP - LLMNR" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $LinkScopedUnicast -RemoteAddress Any `
		-LocalPort Any -RemotePort 5355 `
		-LocalUser $NT_AUTHORITY_NetworkService `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP ports" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $LinkScopedUnicast -RemoteAddress Any `
		-LocalPort Any -RemotePort 1900, 3702 `
		-LocalUser $NT_AUTHORITY_LocalService `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	$mDnsUsers = Get-SDDL -Domain "NT AUTHORITY" -User "NETWORK SERVICE" @Logs
	Merge-SDDL ([ref] $mDnsUsers) $UsersGroupSDDL @Logs

	# NOTE: should be network service
	New-NetFirewallRule -DisplayName "Troubleshoot UDP - mDNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $LinkScopedUnicast -RemoteAddress Any `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser $mDnsUsers `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP - DHCP" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress $LinkScopedUnicast -RemoteAddress Any `
		-LocalPort 546 -RemotePort 547 `
		-LocalUser $NT_AUTHORITY_LocalService `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	Update-Log
}
