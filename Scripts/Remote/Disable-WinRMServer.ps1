
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

.PARAMETER ShowConfig
Display WSMan server configuration on completion

.EXAMPLE
PS> .\Disable-WinRMServer.ps1

.EXAMPLE
PS> .\Disable-WinRMServer.ps1 -ShowConfig

.INPUTS
None. You cannot pipe objects to Disable-WinRMServer.ps1

.OUTPUTS
None. Disable-WinRMServer.ps1 does not generate any output

.NOTES
HACK: Set-WSManInstance may fail with public profile, as a workaround use Set-WSManQuickConfig,
rerun script twice refusing Set-WSManQuickConfig prompt next time.
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

[CmdletBinding(PositionalBinding = $false)]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $ShowConfig
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
# $VerbosePreference = "Continue"

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

# NOTE: WinRM service must be running at this point, handled by ProjectSettings.ps1
$WinRMService = Get-Service -Name WinRM

if ($WinRMService.StartType -ne "Manual")
{
	Write-Information -Tags "User" -MessageData "INFO: Setting WS-Management service to manual startup"
	Set-Service -InputObject $WinRMService -StartupType Manual
}

if ($WinRMService.Status -ne "Running")
{
	Write-Information -Tags "User" -MessageData "INFO: Starting WS-Management service"
	Start-Service -InputObject $WinRMService
}

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

# Remove all custom made session configurations
Write-Verbose -Message "[$ThisModule] Removing non default session configurations"
Get-PSSessionConfiguration -Force |	Where-Object -Property Name -NotLike "Microsoft*" |
Unregister-PSSessionConfiguration -NoServiceRestart -Force

# Disable all session configurations
Write-Verbose -Message "[$ThisModule] Disabling unneeded default session configurations"
Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force

# Enable only localhost or loopback
Write-Verbose -Message "[$ThisModule] Configuring WinRM localhost"
# Set-WSManQuickConfig -SkipNetworkProfileCheck -Force | Out-Null
Enable-PSSessionConfiguration -Name Microsoft.PowerShell -SkipNetworkProfileCheck -NoServiceRestart -Force | Out-Null

Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
New-WSManInstance -SelectorSet @{Address = "*"; Transport = "http" } `
	-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

# New-WSManInstance -SelectorSet @{Address = "IP:[::1]"; Transport = "http" } `
# 	-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

# New-WSManInstance -SelectorSet @{Address = "IP:127.0.0.1"; Transport = "http" } `
# 	-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server authentication options"
# Specify acceptable client authentication methods
# NOTE: HTTP traffic by default only allows messages encrypted with the Negotiate or Kerberos SSP
[hashtable] $AuthenticationOptions = @{
	# The user name and password are sent in clear text.
	# Basic authentication cannot be used with domain accounts
	# The default value is true.
	Basic = $false
	# Authentication by using Kerberos certificates.
	# By default WinRM uses Kerberos for authentication, which does not support IP addresses.
	# The default value is true.
	Kerberos = $false
	# An alternative to Basic Authentication over HTTPS is Negotiate.
	# The server determines whether to use the Kerberos protocol or NTLM.
	# This results in NTLM authentication between the client and server and payload is encrypted over HTTP.
	# NTLM authentication is used by default whenever you specify an IP address.
	# Use the Credential parameter in all remote commands.
	# The Kerberos protocol is selected to authenticate a domain account, and NTLM is selected for local computer accounts.
	# The default value is true.
	Negotiate = $true
	# Certificate-based authentication is a scheme in which the server authenticates a client
	# identified by an X509 certificate.
	# Certificate requirements:
	# The date of the computer falls between the Valid from: to the To: date on the General tab.
	# Host name matches the Issued to: on the General tab, or it matches one of the
	# Subject Alternative Name exactly as displayed on the Details tab.
	# That the Enhanced Key Usage on the Details tab contains Server authentication.
	# On the Certification Path tab that the Current Status is This certificate is OK.
	# The default value is true.
	Certificate = $false
	# Allows the client to use Credential Security Support Provider (CredSSP) authentication.
	# The default value is false.
	CredSSP = $false
}

# TODO: Test registry fix for cases when Negotiate is disabled
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server options"
[hashtable] $ServerOptions = @{
	# NOTE:	AllowRemoteAccess is read only

	# Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
	# The default is 120 seconds.
	MaxPacketRetrievalTimeSeconds = 10

	# Specifies the idle time-out in milliseconds between Pull messages.
	# The default is 60000.
	EnumerationTimeoutms = 6000

	# Allows the client computer to request unencrypted traffic.
	# The default value is false
	AllowUnencrypted = $true
}

try
{
	# NOTE: This will fail if any adapter is on public network, ex. Hyper-V default switch
	# Using winrm gives same result:
	# cmd.exe /C 'winrm set winrm/config/service @{AllowRemoteAccess="false"}'
	Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null
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
			# TODO: Prompt to disable Hyper-V here and Stop-Computer
			Write-Warning -Message "To resolve this problem, uninstall Hyper-V or disable unneeded virtual switches and try again"
		}

		# TODO: Else prompt to disable virtual switches
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
	Write-Warning -Message "Please reboot system"

	if ($ShowConfig)
	{
		Restart-Service -Name WinRM

		# MSDN: Select-Object, beginning in PowerShell 6,
		# it is no longer required to include the Property parameter for ExcludeProperty to work.

		# winrm get winrm/config
		Write-Information -Tags "Project" -MessageData "INFO: Showing all enabled session configurations (short version)"
		Get-PSSessionConfiguration | Where-Object -Property Enabled -EQ True |
		Select-Object -Property Name, Enabled, PSVersion, Architecture, SupportsOptions, lang, AutoRestart, RunAsUser, RunAsPassword, Permission

		# winrm enumerate winrm/config/listener
		Write-Information -Tags "Project" -MessageData "INFO: Showing configured listeners"
		Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate |
		Select-Object -ExcludeProperty cfg, xsi

		# winrm get winrm/config/service
		Write-Information -Tags "Project" -MessageData "INFO: Showing server configuration"
		Get-WSManInstance -ResourceURI winrm/config/Service |
		Select-Object -ExcludeProperty cfg, Auth, DefaultPorts

		# winrm get winrm/config/service/auth
		Write-Information -Tags "Project" -MessageData "INFO: Showing server authentication"
		Get-WSManInstance -ResourceURI winrm/config/Service/Auth | Select-Object -ExcludeProperty cfg

		# winrm get winrm/config/service/defaultports
		Write-Information -Tags "Project" -MessageData "INFO: Showing server default ports"
		Get-WSManInstance -ResourceURI winrm/config/Service/DefaultPorts | Select-Object -ExcludeProperty cfg

		if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose"))
		{
			Write-Verbose -Message "Showing shell configuration"
			Get-Item WSMan:\localhost\Shell\*

			# winrm enumerate winrm/config/plugin
			Write-Verbose -Message "Showing plugin configuration"
			Get-Item WSMan:\localhost\Plugin\*
		}
	}

	Write-Information -Tags "Project" -MessageData "INFO: Stopping WS-Management service"
	Stop-Service -Name WinRM
	Set-Service -Name WinRM -StartupType Manual

	# Remove all WinRM predefined rules (including compatibility)
	Get-NetFirewallRule -Name "WINRM*" -PolicyStore PersistentStore | Remove-NetFirewallRule

	Write-Information -Tags "Project" -MessageData "INFO: Disabling WinRM server is complete"
	# Update-Log
}
