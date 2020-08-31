
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

#
# Reset GPO firewall to factory defaults
#
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $Context $ThisScript @Logs
if (!(Approve-Execute @Logs)) { exit }

#
# Default setup for each profile is the same,
# Separated only for Write-Information output
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Resetting domain firewall profile..." @Logs

Set-NetFirewallProfile -Name Domain -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" @Logs

Write-Information -Tags "User" -MessageData "INFO: Resetting private firewall profile..." @Logs

Set-NetFirewallProfile -Name Private -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" @Logs

Write-Information -Tags "User" -MessageData "INFO: Resetting public firewall profile..." @Logs

Set-NetFirewallProfile -Name Public -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" @Logs

Write-Information -Tags "User" -MessageData "INFO: Resetting global firewall settings..." @Logs

# NOTE: MaxSAIdleTimeSeconds NotConfigured
# This parameter value is case-sensitive and NotConfigured can only be specified using dot-notation
# Otherwise default value is 300
Set-NetFirewallSetting -PolicyStore $PolicyStore -EnablePacketQueuing NotConfigured `
	-EnableStatefulFtp NotConfigured -EnableStatefulPptp NotConfigured `
	-Exemptions NotConfigured -CertValidationLevel NotConfigured `
	-KeyEncoding NotConfigured -RequireFullAuthSupport NotConfigured `
	-MaxSAIdleTimeSeconds 300 -AllowIPsecThroughNAT NotConfigured `
	-RemoteUserTransportAuthorizationList NotConfigured `
	-RemoteUserTunnelAuthorizationList NotConfigured `
	-RemoteMachineTransportAuthorizationList NotConfigured `
	-RemoteMachineTunnelAuthorizationList NotConfigured @Logs `

#
# Remove all the rules
# TODO: Implement removing only project rules.
#

# TODO: we need to check if there are rules present to avoid errors about "no object found"
# Needed also to log actual rule removal errors
Write-Information -Tags "User" -MessageData "INFO: Removing outbound rules..." @Logs
$OutboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Outbound -ErrorAction Ignore | Measure-Object).Count

if ($OutboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Outbound -PolicyStore $PolicyStore @Logs
}

Write-Information -Tags "User" -MessageData "INFO: Removing inbound rules..." @Logs
$InboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Inbound -ErrorAction Ignore | Measure-Object).Count

if ($InboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Inbound -PolicyStore $PolicyStore @Logs
}

Write-Information -Tags "User" -MessageData "INFO: Removing IPSec rules..." @Logs
Remove-NetIPsecRule -All -PolicyStore $PolicyStore @Logs

# Update Local Group Policy for changes to take effect
gpupdate.exe

Write-Information -Tags "User" -MessageData "INFO: Firewall reset is done!" @Logs
Write-Information -Tags "User" -MessageData "INFO: If internet connectivity problem remains, please reboot system" @Logs

Update-Log
