
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
Configures local machine to accept loopback HTTP.

.EXAMPLE
PS> .\Disable-WinRMServer.ps1

.EXAMPLE
PS> .\Disable-WinRMServer.ps1 -ShowConfig

.INPUTS
None. You cannot pipe objects to Disable-WinRMServer.ps1

.OUTPUTS
None. Disable-WinRMServer.ps1 does not generate any output

.NOTES
HACK: Set-WSManInstance may fail with public profile, as a workaround try use Set-WSManQuickConfig.
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Check parameter naming convention
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Client settings are missing
TODO: Not all optional settings are configured

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

[CmdletBinding()]
[OutputType([void])]
param ()

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -Server
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

if (!(Get-NetFirewallRule -Group "@FirewallAPI.dll,-30267" -PolicyStore PersistentStore -EA Ignore))
{
	Write-Verbose -Message "[$ThisModule] Adding firewall rules 'Windows Remote Management'"

	# "Windows Remote Management" predefined rules must be present to continue
	# To remove use -Name WINRM-HTTP-In*
	Copy-NetFirewallRule -PolicyStore SystemDefaults -Group "@FirewallAPI.dll,-30267" `
		-Direction Inbound -NewPolicyStore PersistentStore |
	Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
}

if (!(Get-NetFirewallRule -Group "@FirewallAPI.dll,-30252" -PolicyStore PersistentStore -EA Ignore))
{
	Write-Verbose -Message "[$ThisModule] Adding firewall rules 'Windows Remote Management - Compatibility Mode'"

	# "Windows Remote Management - Compatibility Mode" must be present to be able to modify service settings
	# To remove use -Name WINRM-HTTP-Compat*
	Copy-NetFirewallRule -PolicyStore SystemDefaults -Group "@FirewallAPI.dll,-30252" `
		-Direction Inbound -NewPolicyStore PersistentStore |
	Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
}

# NOTE: WinRM service must be running at this point
$WinRM = Get-Service -Name WinRM

# To start it, it must not be disabled
if ($WinRM.StartType -ne "Automatic")
{
	Write-Information -Tags "User" -MessageData "INFO: Setting WinRM service to automatic startup"
	Set-Service -InputObject $WinRM -StartupType Automatic
}

if ($WinRM.Status -ne "Running")
{
	Write-Information -Tags "User" -MessageData "INFO: Starting WinRM service"
	$WinRM.Start()
	$WinRM.WaitForStatus("Running", $ServiceTimeout)
}

# Remove all non default session configurations
Write-Verbose -Message "[$ThisModule] Removing default session configurations"
Get-PSSessionConfiguration | Where-Object {
	$_.Name -notlike "Microsoft*" -and
	$_.Name -ne "RemoteFirewall"
} | Unregister-PSSessionConfiguration -NoServiceRestart -Force

# Disable all default session configurations
Write-Verbose -Message "[$ThisModule] Disabling unneeded default session configurations"
Disable-PSSessionConfiguration -Name Microsoft* -NoServiceRestart -Force

# Enable only localhost or loopback
Write-Verbose -Message "[$ThisModule] Configuring WinRM localhost"
Set-PSSessionConfiguration -Name RemoteFirewall -AccessMode Local -NoServiceRestart -Force

Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
New-WSManInstance -ResourceURI winrm/config/Listener -ValueSet @{ Enabled = $true } `
	-SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null

# New-WSManInstance -SelectorSet @{Address = "IP:[::1]"; Transport = "HTTP" } `
# 	-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

# New-WSManInstance -SelectorSet @{Address = "IP:127.0.0.1"; Transport = "HTTP" } `
# 	-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server authentication options"

# TODO: Test registry fix for cases when Negotiate is disabled
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server options"

try
{
	# NOTE: This will fail if any adapter is on public network, ex. Hyper-V default switch
	# Using winrm gives same result:
	# cmd.exe /C 'winrm set winrm/config/service @{AllowRemoteAccess="false"}'
	Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null

	Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"
	Set-WSManInstance -ResourceURI winrm/config -ValueSet $ConfigOptions | Out-Null
}
catch [System.InvalidOperationException]
{
	if ([regex]::IsMatch($_.Exception.Message, "either Domain or Private"))
	{
		Write-Error -Category InvalidOperation -TargetObject $ServerOptions -ErrorAction "Continue" `
			-Message "Disabling WinRM server failed because one of the network connection types on this machine is set to 'Public'"

		if ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Server*")
		{
			$HyperV = $null -ne (Get-WindowsFeature -Name Hyper-V |
				Where-Object { $_.InstallState -eq "Installed" })
		}
		else
		{
			$HyperV = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online |
				Select-Object -ExpandProperty State) -eq "Enabled"
		}

		if ($HyperV)
		{
			# TODO: Need to handle this, first check if any VM is running and prompt to disable virtual switches
			Write-Warning -Message "To resolve this problem, uninstall Hyper-V or disable unneeded virtual switches and try again"
		}

		# TODO: Else prompt to uninstall Hyper-V and again disable virtual switches
	}
	else
	{
		Write-Error -ErrorRecord $_ -ErrorAction "Continue"
	}
}
catch
{
	Write-Error -ErrorRecord $_ -ErrorAction "Continue"
}
finally
{
	Write-Verbose -Message "[$ThisModule] Disabling remote access to members of the Administrators group"
	# NOTE: Following is set by Set-WSManQuickConfig and Enable-PSSessionConfiguration, it prevents
	# UAC and allows remote access to members of the Administrators group on the computer.
	Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 0 `
		-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

	if (!$Develop)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Stopping WinRM service"
		Set-Service -Name WinRM -StartupType Manual
		$WinRM.Stop()
		$WinRM.WaitForStatus("Stopped", $ServiceTimeout)
	}

	# Remove all WinRM predefined rules (including compatibility)
	Get-NetFirewallRule -Name "WINRM*" -PolicyStore PersistentStore | Remove-NetFirewallRule

	Update-Log
}

Write-Information -Tags "Project" -MessageData "INFO: Disabling WinRM server is complete"
