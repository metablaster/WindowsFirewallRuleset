
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
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Temporary - IPv4"
$Accept = "Temporary outbound IPv4 rules will be loaded, recommended to temporarily enable specific IPv4 traffic"
$Deny = "Skip operation, temporary outbound IPv4 rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Temporary rules are enable on demand only to let some program do it's internet work, or
# to troubleshoot firewall without shuting it down completely.
#

New-NetFirewallRule -DisplayName "Port 443" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Temporary open port 443 to internet, and disable ASAP." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Port 80" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Temporary open port 80 to internet, and disable ASAP." `
	@Logs | Format-Output @Logs

# NOTE: to make use of this rule, it should be updated here and the script re-run
New-NetFirewallRule -DisplayName "Installer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Enable only to let some installer update or communicate to internet such as
office update, and disable ASAP.
required for ie. downloaded Click-to-Run which does not have persistent location.
Add installer path in script and re-run Temporary.ps1" `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Services" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service "*" -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Enable only to let any service communicate to internet,
useful for troubleshooting, and disable ASAP." `
	@Logs | Format-Output @Logs

# NOTE: This applies to users only, for administrators there is a block rule which must be enabled,
# if the blocking rule for administrators is not enabled this rule will also allow administrators
# there is another todo about possible design in VisualStudio script
$UsersStoreAppsSDDL = Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -UserNames "Your Internet connection, including incoming connections from the Internet"
Merge-SDDL ([ref] $UsersStoreAppsSDDL) (Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -UserNames "Your Internet connection")
Merge-SDDL ([ref] $UsersStoreAppsSDDL) (Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -UserNames "Your home or work networks")
Merge-SDDL ([ref] $UsersStoreAppsSDDL) $UsersGroupSDDL

New-NetFirewallRule -DisplayName "Store Apps" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersStoreAppsSDDL -Owner Any -Package * `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Enable only to let store apps for standard users communicate to internet,
useful for troubleshooting, and disable ASAP." `
	@Logs | Format-Output @Logs

Update-Log

if ($Develop)
{
	#
	# Troubleshooting rules
	# TODO: Some troubleshotting rules apply to both IPv4 and IPv6
	# This traffic fails mostly with virtual adapters, it's not covered by regular rules
	#

	# Accounts used for troubleshooting rules
	# $TroubleshootingAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE" @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot IGMP" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol 2 `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType Any `
		-Description "Temporary allow troublesome IGMP traffic." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP - LLMNR" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort 5355 `
		-LocalUser $NT_AUTHORITY_NetworkService `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP ports" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
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
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser $mDnsUsers `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP - NetBIOS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort 137 -RemotePort 137 `
		-LocalUser $NT_AUTHORITY_System `
		-InterfaceType Any `
		-Description "Temporary allow troublesome UDP traffic." `
		@Logs | Format-Output @Logs

	# Moved from WindowsServices.ps1, used for extension rule below
	$ExtensionAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE" @Logs
	Merge-SDDL ([ref] $ExtensionAccounts) $UsersGroupSDDL @Logs

	# HACK: Temporary using network service account
	# All troubleshooting rules except this one were set to "Enabled",
	# they are now disabled because not needed for everyday life
	New-NetFirewallRule -DisplayName "Troubleshoot BITS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $ServiceHost -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress DefaultGateway4 `
		-LocalPort Any -RemotePort 48300 `
		-LocalUser $ExtensionAccounts `
		-InterfaceType $DefaultInterfaceterface `
		-Description "Extension rule for active users to allow BITS to Internet gateway device (IGD)" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP LooseSourceMapping" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType Any `
		-LocalOnlyMapping $false -LooseSourceMapping $true `
		-Description "Temporary allow all UDP with LooseSourceMapping" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP LocalOnlyMapping" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType Any `
		-LocalOnlyMapping $true -LooseSourceMapping $false `
		-Description "Temporary allow all UDP with LocalOnlyMapping" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "Troubleshoot UDP LocalOnlyMapping + LooseSourceMapping" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType Any `
		-LocalOnlyMapping $true -LooseSourceMapping $true `
		-Description "Temporary allow all UDP with LooseSourceMapping" `
		@Logs | Format-Output @Logs

	Update-Log
}
