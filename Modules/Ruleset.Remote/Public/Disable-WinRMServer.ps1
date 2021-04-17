
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
Disable WinRM server for CIM and PowerShell remoting

.DESCRIPTION
Disable WinRM server for remoting previously enabled by Enable-WinRMServer.
WinRM service will continue to run but will accept only loopback HTTP and only if
using "RemoteFirewall.PSedition" session configuration.

In addition unlike Disable-PSRemoting, it will also remove default firewall rules
and restore registry setting which restricts remote access to members of the
Administrators group on the computer.

.PARAMETER All
If specified, will disable WinRM service completely, remove all listeners and
disable all session configurations.

.EXAMPLE
PS> Disable-WinRMServer

.INPUTS
None. You cannot pipe objects to Disable-WinRMServer

.OUTPUTS
None. Disable-WinRMServer does not generate any output

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations

.LINK
winrm help config
#>
function Disable-WinRMServer
{
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md")]
	[OutputType([void])]
	param (
		[Parameter(ParameterSetName = "All")]
		[switch] $All
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeServer

	<# MSDN: Disabling the session configurations does not undo all the changes made by the
	Enable-PSRemoting or Enable-PSSessionConfiguration cmdlet.
	You might have to manually undo the changes by following these steps:
	1. Stop and disable the WinRM service.
	2. Delete the listener that accepts requests on any IP address.
	3. Disable the firewall exceptions for WS-Management communications.
	4. Restore the value of the LocalAccountTokenFilterPolicy to 0, which restricts remote access to
	members of the Administrators group on the computer.
	#>
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Configuring WinRM service"

	Initialize-WinRM

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Remove all listeners"))
	{
		Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
	}

	if ($All)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable all session configurations and stop WinRM service"))
		{
			Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force

			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Stopping WinRM service"
			Set-Service -Name WinRM -StartupType Disabled
			$WinRM.Stop()
			$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		}
	}
	else
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Leave only '$script:FirewallSession' session configurations enabled"))
		{
			# Disable all session configurations except what's needed for local firewall management
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling session configurations"
			Get-PSSessionConfiguration | Where-Object {
				$_.Name -ne $script:FirewallSession
			} | Disable-PSSessionConfiguration -NoServiceRestart -Force
		}

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Enable only loopback"))
		{
			# Enable only localhost on loopback
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM localhost"
			Set-PSSessionConfiguration -Name $script:FirewallSession -AccessMode Local -NoServiceRestart -Force

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server loopback listener"
			New-WSManInstance -SelectorSet @{Address = "IP:[::1]"; Transport = "HTTP" } `
				-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

			New-WSManInstance -SelectorSet @{Address = "IP:127.0.0.1"; Transport = "HTTP" } `
				-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server authentication options"
			Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null
		}

		try
		{
			Unblock-NetProfile

			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server and protocol options"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server options"
				# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
				# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
				Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM protocol options"
				Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
			}
		}
		catch [System.OperationCanceledException]
		{
			Write-Warning -Message "Operation incomplete because: $($_.Exception.Message)"
		}
		catch
		{
			Write-Error -ErrorRecord $_
		}

		Restore-NetProfile
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling remote access to members of the Administrators group"
	# NOTE: Following is set by Enable-PSRemoting, it prevents UAC and
	# allows remote access to members of the Administrators group on the computer.
	Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 0 `
		-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Remove all WinRM predefined rules"))
	{
		# Remove all WinRM predefined rules
		Remove-NetFirewallRule -Group @($WinRMRules, $WinRMCompatibilityRules) `
			-Direction Inbound -PolicyStore PersistentStore
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Disabling WinRM server is complete"
}
