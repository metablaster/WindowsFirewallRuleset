
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

.GUID 44c95f41-cbeb-4b19-b5f7-daa549c78128

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Configure client computer for WinRM remoting

.DESCRIPTION
Configures client machine to send CIM and PowerShell commands to remote server using WS-Management

.PARAMETER Protocol
Specifies listener protocol to HTTP, HTTPS or both.
By default only HTTPS is configured.

.PARAMETER Domain
Computer name which is to be managed remotely.
If not specified local machine is the default.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default certificate store is searched for certificate with CN entry set to value specified by
-Domain parameter.
If not found, default repository location (\Exports) is searched for DER encoded CER file,
Certificate file must be DER encoded CER file

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server1

Configures client machine to run commands remotely on computer Server1 using SSL,
by installing Server1 certificate into trusted root.

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server2 -CertFile C:\Cert\Server2.cer

Configures client machine to run commands remotely on computer Server2, using SSL
by installing specific certificate into trusted root

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server3 -Protocol HTTP -ShowConfig -SkipTestConnection

Configures client machine to run commands remotely on computer Server3 using HTTP,
when done client configuration is shown and WinRM test is not performed.

.INPUTS
None. You cannot pipe objects to Set-WinRMClient.ps1

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote computer, use Connect-WSMan and New-WSManSessionOption
HACK: Remote HTTPS with "localhost" name in addition to local machine name
TODO: Authenticate users using certificates instead of or optionally in addition to credential object
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Check parameter naming convention
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Remote registry setup and test

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

.LINK
winrm help config
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
[OutputType([void], [System.Xml.XmlElement])]
param (
	[Parameter(Position = 0)]
	[ValidateSet("HTTP", "HTTPS", "Any")]
	[string] $Protocol = "HTTPS",

	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter(ParameterSetName = "File")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "CertThumbPrint")]
	[string] $CertThumbPrint
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -IncludeClient
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true
Write-Information -Tags "Project" -MessageData "INFO: Configuring WinRM service"

if (!(Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore))
{
	Write-Verbose -Message "[$ThisModule] Adding firewall rules 'Windows Remote Management'"

	# "Windows Remote Management" predefined rules must be present to continue
	Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMRules `
		-Direction Inbound -NewPolicyStore PersistentStore |
	Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
}

if (!(Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -EA Ignore))
{
	Write-Verbose -Message "[$ThisModule] Adding firewall rules 'Windows Remote Management - Compatibility Mode'"

	Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMCompatibilityRules `
		-Direction Inbound -NewPolicyStore PersistentStore |
	Set-NetFirewallRule -RemoteAddress Any | Enable-NetFirewallRule
}

# NOTE: WinRM service must be running at this point, handled by ProjectSettings.ps1
$WinRM = Get-Service -Name WinRM

if ($WinRM.StartType -ne "Automatic")
{
	Write-Information -Tags "User" -MessageData "INFO: Setting WS-Management service to automatic startup"
	Set-Service -InputObject $WinRM -StartType Automatic
}

if ($WinRM.Status -ne "Running")
{
	Write-Information -Tags "User" -MessageData "INFO: Starting WS-Management service"
	$WinRM.Start()
	$WinRM.WaitForStatus("Running", $ServiceTimeout)
}

Write-Verbose -Message "[$ThisModule] Configuring WinRM client authentication options"

# NOTE: Not assuming WinRM responds, contact localhost
if (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain)
{
	$AuthenticationOptions["Kerberos"] = $true
}

if ($Protocol -ne "HTTP")
{
	$AuthenticationOptions["Certificate"] = $true
}

try
{
	# NOTE: If this fails, registry fix must precede all other authentication edits
	Set-Item WSMan:\localhost\Client\Auth\Negotiate -Value $AuthenticationOptions["Negotiate"]
}
catch
{
	Write-Warning -Message "Enabling 'Negotiate' authentication failed, doing trough registry..."
	Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ -Name auth_negotiate -Value (
		[int32] ($AuthenticationOptions["Negotiate"] -eq $true))
}

Set-WSManInstance -ResourceURI winrm/config/client/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM client options"

if (($Protocol -ne "HTTPS") -and ($Domain -ne ([System.Environment]::MachineName)))
{
	# TODO: Add instead of set
	$ClientOptions["TrustedHosts"] = $Domain
}

Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"

try
{
	# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
	# cmd.exe /C 'winrm set winrm/config @{MaxTimeoutms=10}'
	Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
}
catch [System.InvalidOperationException]
{
	if ([regex]::IsMatch($_.Exception.Message, "either Domain or Private"))
	{
		Write-Error -Category InvalidOperation -TargetObject $ProtocolOptions -ErrorAction "Continue" `
			-Message "Configuring WinRM client failed because one of the network connection types on this machine is set to 'Public'"

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
		Write-Warning -Message "Configuring WinRM protocol options failed"
	}
}
catch
{
	Write-Warning -Message "Configuring WinRM protocol options failed"
}

if ($Protocol -eq "HTTPS")
{
	# SSL certificate
	[hashtable] $SSLCertParams = @{
		Target = "Client"
		Domain = $Domain
	}

	if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
	elseif (![string]::IsNullOrEmpty($CertThumbPrint)) { $SSLCertParams["CertThumbPrint"] = $CertThumbPrint }
	& $PSScriptRoot\Register-SslCertificate.ps1 @SSLCertParams | Out-Null
}

Write-Verbose -Message "[$ThisModule] Restarting WS-Management service"
$WinRM.Stop()
$WinRM.WaitForStatus("Stopped", $ServiceTimeout)
$WinRM.Start()
$WinRM.WaitForStatus("Running", $ServiceTimeout)

# Remove WinRM predefined compatibility rules
Remove-NetFirewallRule -Group $WinRMCompatibilityRules -Direction Inbound `
	-PolicyStore PersistentStore

# Restore public profile rules to local subnet which is the default
Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore | Where-Object {
	$_.Profile -like "*Public*"
} | Set-NetFirewallRule -RemoteAddress LocalSubnet

Write-Information -Tags "Project" -MessageData "INFO: WinRM client configuration was successful"
Update-Log
