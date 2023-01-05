
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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

.VERSION 0.15.0

.GUID 1cfe2d15-b310-48ad-97ba-fbb46abea6c0

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility, Ruleset.Firewall
#>

<#
.SYNOPSIS
Reset GPO firewall and WinRM to system defaults

.DESCRIPTION
Reset-Firewall script clears all GPO firewall rules and sets all GPO firewall parameters to their
default values.
Resets Windows Remote Management service configuration to system defaults.
Disables PS remoting and restores leftover changes.

.PARAMETER Domain
Specify computer name on which to reset firewall.
The default value is this machine (localhost)

.PARAMETER Remoting
If specified resets and disables Windows remote management service, disables PowerShell remoting and
disables remote registry in addition to firewall reset

.PARAMETER Service
If specified restores modified Windows services to system defaults

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Reset-Firewall

.EXAMPLE
PS> Reset-Firewall -Remoting -Service -Force

.INPUTS
None. You cannot pipe objects to Reset-Firewall.ps1

.OUTPUTS
None. Reset-Firewall.ps1 does not generate any output

.NOTES
TODO: OutputType attribute
TODO: Implement resetting only public, private or domain profile, ShouldProcess
TODO: Remote registry reset is not implemented by Reset-WinRM
HACK: Even after full reset, control panel firewall says "For your security some settings are controlled by Group Policy"

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Position = 0)]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Remoting,

	[Parameter()]
	[switch] $Service,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project

# User prompt
$Accept = "All GPO firewall rules will be removed and modified settings restored to system defaults on '$Domain' computer"
$Deny = "Abort operation, no change will be done to firewall or system on '$Domain' computer"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

#
# Default setup for each profile is the same,
# Separated only for Write-Information output
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags $ThisScript -MessageData "INFO: Resetting domain firewall profile on '$Domain' computer..."

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

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting private firewall profile on '$Domain' computer..."

Set-NetFirewallProfile -Name Private -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting public firewall profile on '$Domain' computer..."

Set-NetFirewallProfile -Name Public -PolicyStore $PolicyStore -Enabled NotConfigured `
	-DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured `
	-AllowInboundRules NotConfigured -AllowLocalFirewallRules NotConfigured `
	-AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
	-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
	-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured `
	-LogMaxSizeKilobytes 4096 -AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName NotConfigured

Write-Information -Tags $ThisScript -MessageData "INFO: Resetting global firewall settings on '$Domain' computer..."

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
Write-Information -Tags $ThisScript -MessageData "INFO: Removing outbound rules on '$Domain' computer..."
$OutboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Outbound -ErrorAction Ignore | Measure-Object).Count

if ($OutboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Outbound -PolicyStore $PolicyStore
}

Write-Information -Tags $ThisScript -MessageData "INFO: Removing inbound rules on '$Domain' computer..."
$InboundCount = (Get-NetFirewallRule -PolicyStore $PolicyStore -Direction Inbound -ErrorAction Ignore | Measure-Object).Count

if ($InboundCount -gt 0)
{
	Remove-NetFirewallRule -Direction Inbound -PolicyStore $PolicyStore
}

Write-Information -Tags $ThisScript -MessageData "INFO: Removing IPSec rules on '$Domain' computer..."
Remove-NetIPsecRule -All -PolicyStore $PolicyStore

# Reset WinRM and PS remoting configuration
if ($Remoting)
{
	if ($Domain -ne [System.Environment]::MachineName)
	{
		Write-Warning -Message "[$ThisScript] Resetting WinRM remotely not possible"
	}
	else
	{
		Reset-WinRM -Confirm:$false
	}
}

# Reset affected services to system defaults

# | Service                                            | Startup                   | Status  |
# |----------------------------------------------------|---------------------------|---------|
# | TCP/IP NetBIOS Helper (lmhosts)                    | Manual (Trigger Start)    | Running |
# | Workstation (LanmanWorkstation)                    | Automatic                 | Running |
# | Server (LanmanServer)                              | Automatic (Trigger Start) | Running |
# | Windows Remote Management (WinRM)                  | Manual                    | Stopped |
# | OpenSSH Authentication Agent (ssh-agent)           | Disabled                  | Stopped |
# | Remote Registry (RemoteRegistry)                   | Disabled                  | Stopped |
# | Function Discovery Provider host (fdPHost)         | Manual                    | Running |
# | Function Discovery Resource Publication (FDResPub) | Manual (Trigger Start)    | Running |

# Services listed above depend on the following services with the following defaults which but are NOT affected

# DisplayName                           Name     StartType  Status  ServiceType
# -----------                           ----     ---------  ------  -----------
# Ancillary Function Driver for Winsock Afd         System Running  KernelDriver
# HTTP Service                          http        Manual Running  KernelDriver
# Server SMB 2.xxx Driver               Srv2        Manual Running  FileSystemDriver
# SMB 2.0 MiniRedirector                MRxSmb20    Manual Running  FileSystemDriver
# Browser                               Bowser      Manual Running  FileSystemDriver

# sc.exe config AFD start= system
# sc.exe config http start= demand
# sc.exe config Srv2 start= demand
# sc.exe config MRxSmb20 start= demand
# sc.exe config Bowser start= demand

# Services listed above (first table) depend on the following services with the following defaults

# DisplayName                           Name     StartType  Status  ServiceType
# -----------                           ----     ---------  ------  -----------
# Remote Procedure Call (RPC)           RpcSs    Automatic Running  Win32ShareProcess
# Security Accounts Manager             SamSS    Automatic Running  Win32ShareProcess
# Network Store Interface Service       NSI      Automatic Running  Win32OwnProcess, Win32ShareProcess
# Remote Procedure Call (RPC)           RPCSS    Automatic Running  Win32ShareProcess

if ($Service)
{
	if ($Domain -ne [System.Environment]::MachineName)
	{
		Write-Warning -Message "[$ThisScript] Resetting services remotely not implemented"
	}
	else
	{
		Write-Information -Tags $ThisScript -MessageData "INFO: Resetting modified windows services to system defaults"

		Set-Service -Name nsi -StartupType Automatic
		Set-Service -Name SamSs -StartupType Automatic

		Set-Service -Name lmhosts -StartupType Manual
		Set-Service -Name LanmanWorkstation -StartupType Automatic
		Set-Service -Name LanmanServer -StartupType Automatic
		Set-Service -Name WinRM -StartupType Manual
		Set-Service -Name RemoteRegistry -StartupType Disabled
		Set-Service -Name fdPHost -StartupType Manual
		Set-Service -Name FDResPub -StartupType Manual

		Start-Service -Name nsi
		Start-Service -Name SamSs

		Start-Service -Name lmhosts
		Start-Service -Name LanmanWorkstation
		Start-Service -Name LanmanServer
		Start-Service -Name fdPHost
		Start-Service -Name FDResPub

		Stop-Service -Name WinRM
		Stop-Service -Name RemoteRegistry

		# Disabling the following services might not be desired so ask for confirmation
		if ($Develop)
		{
			Set-Service -Name ssh-agent -StartupType Disabled -Confirm
			Stop-Service -Name ssh-agent -Confirm

			if (Get-Service -Name sshd -ErrorAction Ignore)
			{
				Set-Service -Name sshd -StartupType Manual -Confirm
				Stop-Service -Name ssh-agent -Confirm
			}
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Session $SessionInstance
	Disconnect-Computer -Domain $Domain
}

Write-Information -Tags $ThisScript -MessageData "INFO: Firewall reset on '$Domain' computer is done!"
Write-Information -Tags $ThisScript -MessageData "INFO: If internet connectivity problem remains, please restart '$Domain' computer"

if (($Remoting -or $Service) -and ($Domain -eq [System.Environment]::MachineName))
{
	# TODO: We should avoid asking to restart console, due to Reset-WinRM running Deploy-Firewall again won't work
	Write-Warning -Message "[$ThisScript] To continue running firewall scripts please restart PowerShell console"
}

Update-Log
