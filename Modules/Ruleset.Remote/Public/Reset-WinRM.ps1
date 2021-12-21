
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Reset WinRM configuration

.DESCRIPTION
Reset-WinRM resets WinRM configuration to either system defaults or to previous settings
that were exported by Export-WinRM

.EXAMPLE
PS> Reset-WinRM

.INPUTS
None. You cannot pipe objects to Reset-WinRM

.OUTPUTS
None. Reset-WinRM does not generate any output

.NOTES
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md
#>
function Reset-WinRM
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeClient -IncludeServer -Default

	Initialize-WinRM

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
			Set-Item -Path WSMan:\localhost\shell\AllowRemoteShellAccess -Value $WinRSOptions["AllowRemoteShellAccess"]
			Set-Item -Path WSMan:\localhost\Shell\IdleTimeout -Value $WinRSOptions["IdleTimeout"]
			Set-Item -Path WSMan:\localhost\Shell\MaxConcurrentUsers -Value $WinRSOptions["MaxConcurrentUsers"]
			Set-Item -Path WSMan:\localhost\Shell\MaxProcessesPerShell -Value $WinRSOptions["MaxProcessesPerShell"]
			Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value $WinRSOptions["MaxMemoryPerShellMB"]
			Set-Item -Path WSMan:\localhost\Shell\MaxShellsPerUser -Value $WinRSOptions["MaxShellsPerUser"]
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
				Set-Item WSMan:\localhost\Client\Auth\Negotiate -Value $AuthenticationOptions["Negotiate"]
			}
		}
		catch
		{
			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Fix 'Negotiate' authentication using registry"))
			{
				Write-Warning -Message "Enabling 'Negotiate' authentication failed, doing trough registry"
				Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ -Name auth_negotiate -Value (
					[int32] ($AuthenticationOptions["Negotiate"] -eq $true))
			}
		}

		# HACK: Not using Set-WSManInstance because it would brick the WinRM service
		Set-Item -Path WSMan:\localhost\client\auth\Kerberos -Value $AuthenticationOptions["Kerberos"]
		Set-Item -Path WSMan:\localhost\client\auth\Certificate -Value $AuthenticationOptions["Certificate"]
		Set-Item -Path WSMan:\localhost\client\auth\Basic -Value $AuthenticationOptions["Basic"]
		Set-Item -Path WSMan:\localhost\client\auth\CredSSP -Value $AuthenticationOptions["CredSSP"]
		Set-Item -Path WSMan:\localhost\client\auth\Digest -Value $AuthenticationOptions["Digest"]
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
		Set-Item -Path WSMan:\localhost\service\auth\Kerberos -Value $AuthenticationOptions["Kerberos"]
		Set-Item -Path WSMan:\localhost\service\auth\Certificate -Value $AuthenticationOptions["Certificate"]
		Set-Item -Path WSMan:\localhost\service\auth\Basic -Value $AuthenticationOptions["Basic"]
		Set-Item -Path WSMan:\localhost\service\auth\CredSSP -Value $AuthenticationOptions["CredSSP"]
		Set-Item -Path WSMan:\localhost\service\auth\CbtHardeningLevel -Value $AuthenticationOptions["CbtHardeningLevel"]
		Set-Item -Path WSMan:\localhost\service\Auth\Negotiate -Value $AuthenticationOptions["Negotiate"]
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
		Unblock-NetProfile

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\service\MaxConcurrentOperationsPerUser -Value $ServerOptions["MaxConcurrentOperationsPerUser"]
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

		Restore-NetProfile
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Remove all listeners"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing all listeners"
		Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset session configurations"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting session configurations"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# "PowerShell." + "current PowerShell version"
			# "PowerShell.7", untied to any specific PowerShell version.
			$DefaultSession = "PowerShell.$($PSVersionTable.PSVersion.Major)*"
		}
		else
		{
			# "Microsoft.PowerShell" is used for sessions by default
			# "Microsoft.PowerShell32" is used for sessions by 32bit host
			# "Microsoft.PowerShell.Workflow" is used by workflows
			$DefaultSession = "Microsoft.PowerShell*"
		}

		# TODO: Will not recreate default sessions if missing or modified
		Get-PSSessionConfiguration | Where-Object {
			$_.Name -notlike $DefaultSession
		} | Unregister-PSSessionConfiguration -NoServiceRestart -Force

		Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Reset registry setting"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting remote access to members of the Administrators group"

		# NOTE: Following is set by Enable-PSRemoting, it prevents UAC and
		# allows remote access to members of the Administrators group on the computer.
		Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 0 `
			-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
	}

	$WmiPlugin = Get-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled
	if ($WmiPlugin.Value -ne $false)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable WMI Provider plugin"))
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting WMI Provider plugin"
			Set-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled -Value $false -WA Ignore
		}
	}

	#
	# Rules and service Reset
	#

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Remove all WinRM predefined rules"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing all WinRM predefined rules"

		# Remove all WinRM predefined rules
		Remove-NetFirewallRule -Group @($WinRMRules, $WinRMCompatibilityRules) `
			-Direction Inbound -PolicyStore PersistentStore
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Stop WinRM service"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Stopping WinRM service"

		Set-Service -Name WinRM -StartupType Disabled
		$WinRM.Stop()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: WinRM reset completed successfully!"
}
