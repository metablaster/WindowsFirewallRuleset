
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

<#PSScriptInfo

.VERSION 0.10.1

.GUID 8b38bd61-6389-4171-85a2-66e66fc7e72f

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Disable WinRM server for CIM and PowerShell remoting

.DESCRIPTION
Disable WinRM server for remoting previously enabled by Enable-WinRMServer.
WinRM service will continue to run but will accept only loopback HTTP and only if
using "RemoteFirewall" session configuration.

In addition unlike Disable-PSRemoting, it will also remove default firewall rules
and restore registry setting which restricts remote access to members of the
Administrators group on the computer.

.PARAMETER All
If specified, will disable WinRM service completely, remove all listeners and
disable all session configurations.

.PARAMETER Force
If specified, does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

.EXAMPLE
PS> .\Disable-WinRMServer.ps1

.INPUTS
None. You cannot pipe objects to Disable-WinRMServer.ps1

.OUTPUTS
None. Disable-WinRMServer.ps1 does not generate any output

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Remote registry disable

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations

.LINK
winrm help config
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = "Default")]
[OutputType([void])]
param (
	[Parameter(ParameterSetName = "All")]
	[switch] $All,

	[Parameter(ParameterSetName = "Default")]
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -IncludeServer
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true

<# MSDN: Disabling the session configurations does not undo all the changes made by the
Enable-PSRemoting or Enable-PSSessionConfiguration cmdlet.
You might have to manually undo the changes by following these steps:
1. Stop and disable the WinRM service.
2. Delete the listener that accepts requests on any IP address.
3. Disable the firewall exceptions for WS-Management communications.
4. Restore the value of the LocalAccountTokenFilterPolicy to 0, which restricts remote access to
members of the Administrators group on the computer.
#>
Write-Information -Tags "Project" -MessageData "INFO: Configuring WinRM service"

& $PSScriptRoot\Initialize-WinRM.ps1 -EA Stop -Force
Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse

if ($All)
{
	Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force

	Write-Information -Tags "Project" -MessageData "INFO: Stopping WinRM service"
	Set-Service -Name WinRM -StartupType Disabled
	$WinRM.Stop()
	$WinRM.WaitForStatus("Stopped", $ServiceTimeout)
}
else
{
	# Disable all session configurations except what's needed for local firewall management
	Write-Verbose -Message "[$ThisModule] Disabling session configurations"
	Get-PSSessionConfiguration | Where-Object {
		$_.Name -ne "RemoteFirewall"
	} | Disable-PSSessionConfiguration -NoServiceRestart -Force

	# Enable only localhost on loopback
	Write-Verbose -Message "[$ThisModule] Configuring WinRM localhost"
	Set-PSSessionConfiguration -Name RemoteFirewall -AccessMode Local -NoServiceRestart -Force

	Write-Verbose -Message "[$ThisModule] Configuring WinRM server loopback listener"
	New-WSManInstance -SelectorSet @{Address = "IP:[::1]"; Transport = "HTTP" } `
		-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

	New-WSManInstance -SelectorSet @{Address = "IP:127.0.0.1"; Transport = "HTTP" } `
		-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

	Write-Verbose -Message "[$ThisModule] Configuring WinRM server authentication options"
	# TODO: Test registry fix for cases when Negotiate is disabled (see Set-WinRMClient.ps1)
	Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

	[array] $VirtualAdapter = $null

	try
	{
		if ($Workstation)
		{
			[array] $PublicAdapter = Get-NetConnectionProfile |
			Where-Object -Property NetworkCategory -NE Private

			if ($PublicAdapter)
			{
				Write-Warning -Message "Following network adapters need to be set to private network profile to continue"
				foreach ($Alias in $PublicAdapter.InterfaceAlias)
				{
					if ($Force -or $PSCmdlet.ShouldContinue($Alias, "Set adapter to private network profile"))
					{
						Set-NetConnectionProfile -InterfaceAlias $Alias -NetworkCategory Private -Force
					}
					else
					{
						throw [System.OperationCanceledException]::new("not all connected network adapters are not operating on private profile")
					}
				}
			}

			$VirtualAdapter = Get-NetIPConfiguration | Where-Object { !$_.NetProfile }

			if ($VirtualAdapter)
			{
				Write-Warning -Message "Following network adapters need to be temporarily disabled to continue"
				foreach ($Alias in $VirtualAdapter.InterfaceAlias)
				{
					if ($Force -or $PSCmdlet.ShouldContinue($Alias, "Temporarily disable network adapter"))
					{
						Disable-NetAdapter -InterfaceAlias $Alias -Confirm:$false
					}
					else
					{
						throw [System.OperationCanceledException]::new("not all configured network adapters are not operating on private profile")
					}
				}
			}
		}

		Write-Verbose -Message "[$ThisModule] Configuring WinRM server options"
		# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
		# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
		Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null

		Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"
		Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
	}
	catch [System.OperationCanceledException]
	{
		Write-Warning -Message "Operation incomplete because $($_.Exception.Message)"
	}
	catch
	{
		Write-Error -ErrorRecord $_ -ErrorAction "Continue"
	}

	if ($Workstation -and $VirtualAdapter)
	{
		foreach ($Alias in $VirtualAdapter.InterfaceAlias)
		{
			if ($Force -or $PSCmdlet.ShouldProcess($Alias, "Re-enable network adapter"))
			{
				Enable-NetAdapter -InterfaceAlias $Alias
			}
		}
	}
}

Write-Verbose -Message "[$ThisModule] Disabling remote access to members of the Administrators group"
# NOTE: Following is set by Enable-PSRemoting, it prevents UAC and
# allows remote access to members of the Administrators group on the computer.
Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 0 `
	-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Remove all WinRM predefined rules
Remove-NetFirewallRule -Group @($WinRMRules, $WinRMCompatibilityRules) `
	-Direction Inbound -PolicyStore PersistentStore

Write-Information -Tags "Project" -MessageData "INFO: Disabling WinRM server is complete"
Update-Log
