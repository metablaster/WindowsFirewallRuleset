
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
# Setup firewall profile, network profile and global firewall behavior
#
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Setup local variables
$Accept = "Set global firewall behavior, adjust firewall settings and set up firewall and network profile"
$Deny = "Skip operation, no change will be done to firewall or network profile"

# User prompt
Update-Context $Context $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

#
# TODO: how to set and reset settings found in IPSec tab?
# TODO: it looks like private profile traffic is logged into public log and vice versa
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up public firewall profile..." @Logs

Set-NetFirewallProfile -Profile Public -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast False `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\PublicFirewall.log" @Logs

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up private firewall profile..." @Logs

Set-NetFirewallProfile -Profile Private -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\PrivateFirewall.log" @Logs

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up domain firewall profile..." @Logs

Set-NetFirewallProfile -Profile Domain -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\DomainFirewall.log" @Logs

Write-Information -Tags "User" -MessageData "INFO: Setting up global firewall settings..." @Logs

# Modify the global firewall settings of the target computer.
# Configures properties that apply to the firewall and IPsec settings,
# regardless of which network profile is currently in use.
Set-NetFirewallSetting -PolicyStore $PolicyStore `
	-EnableStatefulFtp True -EnableStatefulPptp False -EnablePacketQueuing NotConfigured `
	-Exemptions None -CertValidationLevel RequireCrlCheck `
	-KeyEncoding UTF8 -RequireFullAuthSupport NotConfigured `
	-MaxSAIdleTimeSeconds 300 -AllowIPsecThroughNAT NotConfigured `
	-RemoteUserTransportAuthorizationList None -RemoteUserTunnelAuthorizationList None `
	-RemoteMachineTransportAuthorizationList None -RemoteMachineTunnelAuthorizationList None @Logs `

# Set default firewall profile for network adapter
Set-NetworkProfile @Logs

Update-Log
