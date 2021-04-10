
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
Configures client machine to send CIM and PowerShell commands to remote server using WS-Management.
This functionality is most useful when setting up WinRM with SSL.

.PARAMETER Domain
Computer name which is to be managed remotely from this machine.
If not specified local machine is the default.

.PARAMETER Protocol
Specifies protocol to HTTP, HTTPS or both.
By default only HTTPS is configured.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default certificate store is searched for certificate with CN entry set to value specified by
-Domain parameter.
If not found, default repository location (\Exports) is searched for DER encoded CER file.

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER Force
Also it does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server1

Configures client machine to run commands remotely on computer Server1 using SSL,
by installing Server1 certificate into trusted root.

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server2 -CertFile C:\Cert\Server2.cer

Configures client machine to run commands remotely on computer Server2, using SSL
by installing specified certificate file into trusted root store.

.EXAMPLE
PS> .\Set-WinRMClient.ps1 -Domain Server3 -Protocol HTTP

Configures client machine to run commands remotely on computer Server3 using HTTP

.INPUTS
None. You cannot pipe objects to Set-WinRMClient.ps1

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote computer, use Connect-WSMan and New-WSManSessionOption
TODO: Authenticate users using certificates optionally or instead of credential object
TODO: Needs testing with PS Core
TODO: Risk mitigation
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
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[ValidateSet("HTTP", "HTTPS", "Any")]
	[string] $Protocol = "HTTPS",

	[Parameter(ParameterSetName = "File")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "CertThumbPrint")]
	[string] $CertThumbPrint,

	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -IncludeClient
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true
Write-Information -Tags "Project" -MessageData "INFO: Configuring WinRM service"

& $PSScriptRoot\Initialize-WinRM.ps1 -EA Stop -Force

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
	# TODO: WinRM service should be restarted to pick up our fix?
	Write-Warning -Message "Enabling 'Negotiate' authentication failed, doing trough registry..."
	Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ -Name auth_negotiate -Value (
		[int32] ($AuthenticationOptions["Negotiate"] -eq $true))
}

Set-WSManInstance -ResourceURI winrm/config/client/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM default client ports"
Set-WSManInstance -ResourceURI winrm/config/client/DefaultPorts -ValueSet $PortOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM client options"

if (($Protocol -ne "HTTPS") -and ($Domain -ne ([System.Environment]::MachineName)))
{
	# TODO: Add instead of replace
	$ClientOptions["TrustedHosts"] = $Domain
}

Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null

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

	Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"
	# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
	# cmd.exe /C 'winrm set winrm/config @{ MaxTimeoutms = 10 }'
	Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null

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
catch [System.OperationCanceledException]
{
	Write-Warning -Message "Operation incomplete because $($_.Exception.Message)"
}
catch
{
	Write-Error -ErrorRecord $_ -ErrorAction "Continue"
}

if ($Protocol -eq "HTTPS")
{
	# SSL certificate
	[hashtable] $SSLCertParams = @{
		ProductType = "Client"
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

if ($Workstation)
{
	# Restore public profile rules to local subnet which is the default
	Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore | Where-Object {
		$_.Profile -like "*Public*"
	} | Set-NetFirewallRule -RemoteAddress LocalSubnet
}

Write-Information -Tags "Project" -MessageData "INFO: WinRM client configuration was successful"
Update-Log
