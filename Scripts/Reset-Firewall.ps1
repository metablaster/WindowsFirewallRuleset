
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

<#PSScriptInfo

.VERSION 0.12.0

.GUID 1cfe2d15-b310-48ad-97ba-fbb46abea6c0

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Reset GPO firewall and WinRM to factory defaults

.DESCRIPTION
Reset-Firewall script clears all GPO firewall rules and sets all GPO firewall parameters to their
default values.
Resets Windows Remote Management service configuration to factory defaults.
Disables PS remoting and restores leftover changes.

.PARAMETER Remoting
If specified resets and disables Windows remote management service, disables PowerShell remoting and
disabled remote registry in addition to firewall reset

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Reset-Firewall.ps1

.INPUTS
None. You cannot pipe objects to Reset-Firewall.ps1

.OUTPUTS
None. Reset-Firewall.ps1 does not generate any output

.NOTES
TODO: OutputType attribute
TODO: Implement resetting only public, private or domain profile, ShouldProcess
TODO: Remote registry reset is not implemented by Reset-WinRM

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Remoting,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

# User prompt
$Accept = "All GPO firewall rules will be removed and settings restored to factory defaults"
$Deny = "Abort operation, no change will be done to firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

#
# Default setup for each profile is the same,
# Separated only for Write-Information output
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags $ThisScript -MessageData "INFO: Resetting domain firewall profile..."

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

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting private firewall profile..."

Set-NetFirewallProfile -Name Private -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting public firewall profile..."

Set-NetFirewallProfile -Name Public -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting global firewall settings..."

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
Write-Information -Tags $ThisScript -MessageData "INFO: Removing outbound rules..."
$OutboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Outbound -ErrorAction Ignore | Measure-Object).Count

if ($OutboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Outbound -PolicyStore $PolicyStore
}

Write-Information -Tags $ThisScript -MessageData "INFO: Removing inbound rules..."
$InboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Inbound -ErrorAction Ignore | Measure-Object).Count

if ($InboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Inbound -PolicyStore $PolicyStore
}

Write-Information -Tags $ThisScript -MessageData "INFO: Removing IPSec rules..."
Remove-NetIPsecRule -All -PolicyStore $PolicyStore

# Update Local Group Policy for changes to take effect
Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"

# Reset WinRM and PS remoting configuration
if ($Remoting)
{
	Reset-WinRM -Confirm:$false
}

Write-Information -Tags $ThisScript -MessageData "INFO: Firewall reset is done!"
Write-Information -Tags $ThisScript -MessageData "INFO: If internet connectivity problem remains, please reboot system"

if ($Remoting)
{
	# TODO: We should avoid asking to restart console, due to Reset-WinRM running Deploy-Firewall again won't work
	Write-Warning -Message "[$ThisScript] To continue running firewall scripts please restart PowerShell console"
}

Update-Log
