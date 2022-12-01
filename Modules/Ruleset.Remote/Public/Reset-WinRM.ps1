
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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

using namespace System.ServiceProcess

<#
.SYNOPSIS
Reset WinRM and PS remoting configuration

.DESCRIPTION
Reset-WinRM resets WinRM configuration to system defaults.
PS remoting is disabled and WinRM service is reset to defaults,
default firewall rules are disabled and WinRM service is stopped and set to manual.

.EXAMPLE
PS> Reset-WinRM

.INPUTS
None. You cannot pipe objects to Reset-WinRM

.OUTPUTS
None. Reset-WinRM does not generate any output

.NOTES
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Need to reset changes done by Enable-RemoteRegistry, separate function is desired
TODO: Restoring old setup not implemented
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected
TODO: Parameter which will allow resetting to custom settings in addition to factory reset
TODO: Somewhere it asks for confirmation to start WinRM service, to repro reset in Windows Powershell
and then again in Core

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md
#>
function Reset-WinRM
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeClient -IncludeServer -Default

	Initialize-WinRM
	Unblock-NetProfile

	#
	# PowerShell specific reset
	#

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset session configurations"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting session configurations"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# Exclude non Core default sessions
			$ExcludeSession = "Microsoft.PowerShell*"
		}
		else
		{
			# Exclude non Desktop default sessions
			$ExcludeSession = "PowerShell.$($PSVersionTable.PSVersion.Major)*"
		}

		# Recreating default sessions involves removing existing ones and then
		# populating fresh ones with Enable-PSRemoting
		Get-PSSessionConfiguration -Name * | Where-Object {
			$_.Name -notlike $ExcludeSession
		} | Unregister-PSSessionConfiguration -NoServiceRestart -Force

		# NOTE: Enable-PSRemoting may fail in Windows PowerShell
		Set-StrictMode -Off
		Enable-PSRemoting -Force -WarningAction Ignore | Out-Null
		Set-StrictMode -Version Latest

		Disable-PSRemoting -Force -WarningAction Ignore
	}

	# NOTE: This registry key does not affect computers that are members of an Active Directory domain.
	# In this case, Enable-PSRemoting does not create the key,
	# and you don't have to set it to 0 after disabling remoting with Disable-PSRemoting
	if (!(Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain))
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset registry setting to allow remote access to Administrators"))
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting remote access to members of the Administrators group"

			# NOTE: Following is set by Enable-PSRemoting, it prevents UAC and
			# allows remote access to members of the Administrators group on the computer.
			# By default this value does not exist
			Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy -ErrorAction Ignore
		}
	}

	$WmiPlugin = Get-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled
	if ($WmiPlugin.Value -eq $false)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable WMI Provider plugin"))
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WMI Provider plugin"
			Set-Item -Path WSMan:\localhost\Plugin\"WMI Provider"\Enabled -Value $true -WA Ignore
		}
	}

	#
	# WinRM reset
	#

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRM protocol options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM protocol options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\config\MaxEnvelopeSizekb -Value $ProtocolOptions["MaxEnvelopeSizekb"]
			Set-Item -Path WSMan:\localhost\config\MaxTimeoutms -Value $ProtocolOptions["MaxTimeoutms"]
			Set-Item -Path WSMan:\localhost\config\MaxBatchItems -Value $ProtocolOptions["MaxBatchItems"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRS options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRS options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# NOTE: Disable warnings which say:
			# The updated configuration might affect the operation of the plugins having a per plugin quota value greater than
			$PreviousPreference = $WarningPreference
			$WarningPreference = "SilentlyContinue"
			Set-Item -Path WSMan:\localhost\shell\AllowRemoteShellAccess -Value $WinRSOptions["AllowRemoteShellAccess"]
			Set-Item -Path WSMan:\localhost\Shell\IdleTimeout -Value $WinRSOptions["IdleTimeout"]
			Set-Item -Path WSMan:\localhost\Shell\MaxConcurrentUsers -Value $WinRSOptions["MaxConcurrentUsers"]
			Set-Item -Path WSMan:\localhost\Shell\MaxProcessesPerShell -Value $WinRSOptions["MaxProcessesPerShell"]
			Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value $WinRSOptions["MaxMemoryPerShellMB"]
			Set-Item -Path WSMan:\localhost\Shell\MaxShellsPerUser -Value $WinRSOptions["MaxShellsPerUser"]
			$WarningPreference = $PreviousPreference
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet $WinRSOptions | Out-Null
		}
	}

	#
	# Client reset
	#

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRM client authentication options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM client authentication options"

		try
		{
			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Attempt to set client 'Negotiate' authentication"))
			{
				# NOTE: If this fails, registry fix must precede all other authentication edits
				Set-Item -Path WSMan:\localhost\Client\Auth\Negotiate -Value $ClientAuthenticationOptions["Negotiate"]
			}
		}
		catch
		{
			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Fix 'Negotiate' authentication using registry"))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Enabling 'Negotiate' authentication failed, doing trough registry"
				Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ -Name auth_negotiate -Value (
					[int32] ($ClientAuthenticationOptions["Negotiate"] -eq $true))
			}
		}

		# HACK: Not using Set-WSManInstance because it would brick the WinRM service
		Set-Item -Path WSMan:\localhost\client\auth\Kerberos -Value $ClientAuthenticationOptions["Kerberos"]
		Set-Item -Path WSMan:\localhost\client\auth\Certificate -Value $ClientAuthenticationOptions["Certificate"]
		Set-Item -Path WSMan:\localhost\client\auth\Basic -Value $ClientAuthenticationOptions["Basic"]
		Set-Item -Path WSMan:\localhost\client\auth\CredSSP -Value $ClientAuthenticationOptions["CredSSP"]
		Set-Item -Path WSMan:\localhost\client\auth\Digest -Value $ClientAuthenticationOptions["Digest"]
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRM client port options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM client port options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\client\DefaultPorts\HTTP -Value $PortOptions["HTTP"]
			Set-Item -Path WSMan:\localhost\client\DefaultPorts\HTTPS -Value $PortOptions["HTTPS"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/client/DefaultPorts -ValueSet $PortOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset client options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM client options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\client\NetworkDelayms -Value $ClientOptions["NetworkDelayms"]
			Set-Item -Path WSMan:\localhost\client\URLPrefix -Value $ClientOptions["URLPrefix"]
			Set-Item -Path WSMan:\localhost\client\AllowUnencrypted -Value $ClientOptions["AllowUnencrypted"]
			Set-Item -Path WSMan:\localhost\client\TrustedHosts -Value $ClientOptions["TrustedHosts"] -Force
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null
		}
	}

	#
	# Server reset
	#

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRM server authentication options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM server authentication options"

		# HACK: Not using Set-WSManInstance because it would brick the WinRM service
		Set-Item -Path WSMan:\localhost\service\auth\Kerberos -Value $ServerAuthenticationOptions["Kerberos"]
		Set-Item -Path WSMan:\localhost\service\auth\Certificate -Value $ServerAuthenticationOptions["Certificate"]
		Set-Item -Path WSMan:\localhost\service\auth\Basic -Value $ServerAuthenticationOptions["Basic"]
		Set-Item -Path WSMan:\localhost\service\auth\CredSSP -Value $ServerAuthenticationOptions["CredSSP"]
		Set-Item -Path WSMan:\localhost\service\auth\CbtHardeningLevel -Value $ServerAuthenticationOptions["CbtHardeningLevel"]
		Set-Item -Path WSMan:\localhost\service\Auth\Negotiate -Value $ServerAuthenticationOptions["Negotiate"]
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset WinRM server port options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM server port options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTP -Value $PortOptions["HTTP"]
			Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTPS -Value $PortOptions["HTTPS"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/service/DefaultPorts -ValueSet $PortOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset server options"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WinRM server options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# NOTE: Disable warning which say:
			# The updated configuration might affect the operation of the plugins having a per plugin quota value greater than
			Set-Item -Path WSMan:\localhost\service\MaxConcurrentOperationsPerUser `
				-Value $ServerOptions["MaxConcurrentOperationsPerUser"] -WarningAction SilentlyContinue

			Set-Item -Path WSMan:\localhost\service\EnumerationTimeoutms -Value $ServerOptions["EnumerationTimeoutms"]
			Set-Item -Path WSMan:\localhost\service\MaxConnections -Value $ServerOptions["MaxConnections"]
			Set-Item -Path WSMan:\localhost\service\MaxPacketRetrievalTimeSeconds -Value $ServerOptions["MaxPacketRetrievalTimeSeconds"]
			Set-Item -Path WSMan:\localhost\service\AllowUnencrypted -Value $ServerOptions["AllowUnencrypted"]
			Set-Item -Path WSMan:\localhost\service\IPv4Filter -Value $ServerOptions["IPv4Filter"]
			Set-Item -Path WSMan:\localhost\service\IPv6Filter -Value $ServerOptions["IPv6Filter"]
			Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpListener -Value $ServerOptions["EnableCompatibilityHttpListener"]
			Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpsListener -Value $ServerOptions["EnableCompatibilityHttpsListener"]
		}
		else
		{
			# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
			# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
			Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null
		}
	}

	Restore-NetProfile

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Remove all listeners"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing all listeners"
		Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			New-Item -Path WSMan:\localhost\Listener -Address "*" -Transport HTTP -Enabled $true -Force | Out-Null
		}
		else
		{
			New-WSManInstance -SelectorSet @{ Address = "*"; Transport = "HTTP" } `
				-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null
		}
	}

	#
	# Rules and service Reset
	#

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Disable all WinRM predefined rules"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing all WinRM predefined rules"

		# Disable all WinRM predefined rules
		# NOTE: By default rules should be present but disabled, we just handle disabling then if present
		Get-NetFirewallRule -Group @($WinRMRules, $WinRMCompatibilityRules) -Direction Inbound `
			-PolicyStore PersistentStore -ErrorAction Ignore | Disable-NetFirewallRule
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Stop WinRM service and set to manual"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Stopping WinRM service"

		$WinRM.Stop()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		Set-Service -Name WinRM -StartupType Manual
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: WinRM reset completed successfully!"
}
