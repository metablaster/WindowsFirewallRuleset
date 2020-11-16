
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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - DnsCrypt"
$Accept = "Outbound rules for DnsCrypt software will be loaded, recommended if DnsCrypt software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for DnsCrypt software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# DnsCrypt installation directories
#
$DnsCryptRoot = "%ProgramFiles%\Simple DNSCrypt x64"

#
# DnsCrypt rules
# TODO: remote servers from file, explicit TCP or UDP
# HACK: If localhost (DNSCrypt) is the only DNS server (no secondary DNS) then network status will be
# "No internet access" even though internet works just fine
# TODO: Add rule for "Global resolver", dnscrypt-proxy acting as server
# https://www.cloudflare.com/learning/dns/dns-over-tls/
#

# Test if installation exists on system
if ((Test-Installation "DnsCrypt" ([ref] $DnsCryptRoot) @Logs) -or $ForceLoad)
{
	$Program = "$DnsCryptRoot\dnscrypt-proxy\dnscrypt-proxy.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "dnscrypt-proxy" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service dnscrypt-proxy -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443, 853 `
		-LocalUser Any `
		-InterfaceType $DefaultInterfaceterface `
		-Description "DNSCrypt is a protocol that authenticates communications between a DNS client
and a DNS resolver. It prevents DNS spoofing.
It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver
and haven't been tampered with.
This rule applies to both TLS and HTTPS encrypted DNS using dnscrypt-proxy." `
		@Logs | Format-Output @Logs

	# $NT_AUTHORITY_System
	# TODO: see if LooseSourceMapping is needed
	New-NetFirewallRule -DisplayName "dnscrypt-proxy" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service dnscrypt-proxy -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443, 853 `
		-LocalUser Any `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-InterfaceType $DefaultInterfaceterface `
		-Description "DNSCrypt is a protocol that authenticates communications between a DNS client
and a DNS resolver. It prevents DNS spoofing.
It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver and
haven't been tampered with.
This rule applies to both TLS and HTTPS encrypted DNS using dnscrypt-proxy." `
		@Logs | Format-Output @Logs

	$Program = "$DnsCryptRoot\SimpleDnsCrypt.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "Simple DNS Crypt" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $AdministratorsGroupSDDL `
		-InterfaceType $DefaultInterfaceterface `
		-Description "Simple DNS Crypt update check on startup" `
		@Logs | Format-Output @Logs
}

Update-Log
