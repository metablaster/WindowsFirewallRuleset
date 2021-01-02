
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

<#PSScriptInfo

.VERSION 0.9.1

.GUID 1cfe2d15-b310-48ad-97ba-fbb46abea6c0

.AUTHOR metablaster zebal@protonmail.com

.COPYRIGHT Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

.TAGS Firewall Security

.LICENSEURI https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE

.PROJECTURI https://github.com/metablaster/WindowsFirewallRuleset

.RELEASENOTES
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/CHANGELOG.md
#>

<#
.SYNOPSIS
Reset GPO firewall to factory defaults

.DESCRIPTION
SetupFirewall script clears all GPO firewall rules and sets all GPO firewall
parameter to their default values

.EXAMPLE
PS> .\ResetFirewall.ps1

.INPUTS
None. You cannot pipe objects to ResetFirewall.ps1

.OUTPUTS
None. ResetFirewall.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -Version 5.1
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# Setup local variables
$Accept = "All firewall rules and settings will be restored to factory defaults"
$Deny = "Abort operation, no change will be done to firewall"

# User prompt
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

#
# Default setup for each profile is the same,
# Separated only for Write-Information output
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Resetting domain firewall profile..."

# NOTE: LogMaxSizeKilobytes: The default setting when managing a computer is 4096.
# When managing a GPO, the default setting is NotConfigured.
# LogFileName: "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log"
# Not possible to do these 2 defaults here, use GPO instead
Set-NetFirewallProfile -Name Domain -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags "User" -MessageData "INFO: Resetting private firewall profile..."

Set-NetFirewallProfile -Name Private -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags "User" -MessageData "INFO: Resetting public firewall profile..."

Set-NetFirewallProfile -Name Public -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags "User" -MessageData "INFO: Resetting global firewall settings..."

# NOTE: MaxSAIdleTimeSeconds: The default value when managing a local computer is 300 seconds (5 minutes).
# When managing a GPO, the default value is NotConfigured.
# Not possible to set this default here, use GPO instead
Set-NetFirewallSetting -PolicyStore $PolicyStore -EnablePacketQueuing NotConfigured `
	-EnableStatefulFtp NotConfigured -EnableStatefulPptp NotConfigured `
	-Exemptions NotConfigured -CertValidationLevel NotConfigured `
	-KeyEncoding NotConfigured -RequireFullAuthSupport NotConfigured `
	-MaxSAIdleTimeSeconds 300 -AllowIPsecThroughNAT NotConfigured `
	-RemoteUserTransportAuthorizationList NotConfigured `
	-RemoteUserTunnelAuthorizationList NotConfigured `
	-RemoteMachineTransportAuthorizationList NotConfigured `
	-RemoteMachineTunnelAuthorizationList NotConfigured `

#
# Remove all the rules
# TODO: Implement removing only project rules.
#

# TODO: we need to check if there are rules present to avoid errors about "no object found"
# Needed also to log actual rule removal errors
Write-Information -Tags "User" -MessageData "INFO: Removing outbound rules..."
$OutboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Outbound -ErrorAction Ignore | Measure-Object).Count

if ($OutboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Outbound -PolicyStore $PolicyStore
}

Write-Information -Tags "User" -MessageData "INFO: Removing inbound rules..."
$InboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Inbound -ErrorAction Ignore | Measure-Object).Count

if ($InboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Inbound -PolicyStore $PolicyStore
}

Write-Information -Tags "User" -MessageData "INFO: Removing IPSec rules..."
Remove-NetIPsecRule -All -PolicyStore $PolicyStore

# Update Local Group Policy for changes to take effect
gpupdate.exe /target:computer

Write-Information -Tags "User" -MessageData "INFO: Firewall reset is done!"
Write-Information -Tags "User" -MessageData "INFO: If internet connectivity problem remains, please reboot system"

Update-Log
