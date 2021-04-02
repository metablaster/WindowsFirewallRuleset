
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

.GUID 5f0b8c02-a28a-4e8b-b355-7478bc0bd665

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Configure computer for HTTPS remoting

.DESCRIPTION
Configures either remote or management machine for WS-Management via HTTPS.
This script should be run first on remote machine and then on management machine.

.PARAMETER Domain
Computer name which is to be managed remotely.
Certificate store is searched for certificate with CN entry set to this name,
If not found, certificate specified by CertFile is imported.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default new self signed certifcate is made if none exists.

.PARAMETER Remote
Should be specified when configuring remote computer

.PARAMETER NoClobber
Prevents an exported certificate file from overwriting an existing certificate file.
Instead warning message is shown.

.PARAMETER Force
If specified, does not prompt to create a listener and overwrites an existing certificate file,
even if it has the Read-only attribute set.

.EXAMPLE
PS> .\Set-WSManHTTPS.ps1 -Domain Server01

Configures management machine by installing certificate of a remote computer

.EXAMPLE
PS> .\Set-WSManHTTPS.ps1 -Remote -NoClobber

Configures WinRM on remote computer for HTTPS

.INPUTS
None. You cannot pipe objects to Set-WSManHTTPS.ps1

.OUTPUTS
None. Set-WSManHTTPS.ps1 does not generate any output

.NOTES
TODO: This script must be part of Ruleset.Initialize module
NOTE: Following will be set by something in this script, it prevents remote UAC
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote use Connect-WSMan and New-WSManSessionOption
TODO: Optional HTTP configuration
HACK: Remote HTTPS with localhost in addition to local machine name

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configuration_files?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Local")]
param (
	[Parameter(Mandatory = $true, ParameterSetName = "Local")]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter()]
	[string] $CertFile,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $Remote,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $Force,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $NoClobber
)

# NOTE: Needed only by Test-Credential and $ProjectRoot
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$CertPath = "$ProjectRoot\Exports"

if ($Remote)
{
	# Remote machine
	$Domain = [System.Environment]::MachineName
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	$CertCount = ($Cert | Measure-Object).Count

	if ($CertCount -gt 1)
	{
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates match"
		return
	}
	elseif ($CertCount -eq 0)
	{
		$Date = Get-Date
		Write-Information -Tags "Project" -MessageData "INFO: Creating new certificate"

		# TODO: -Signer -KeySpec -HashAlgorithm -Subject "localhost"
		$Cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation "Cert:\LocalMachine\My" `
			-FriendlyName "RemoteFirewall" -KeyAlgorithm RSA -KeyDescription "PSRemotingKey" `
			-KeyFriendlyName "RemoteFirewall" -KeyLength 2048 -Type SSLServerAuthentication `
			-KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy ExportableEncrypted `
			-NotBefore $Date -NotAfter $Date.AddMonths(6)
	}
	else
	{
		Write-Information -Tags "Project" -MessageData "INFO: Using existing certificate"
	}

	# TODO: Search entry path for CN entries instead
	if ([string]::IsNullOrEmpty($CertFile))
	{
		$CertFile = "$CertPath\$Domain.cer"
	}

	$ExportParams = @{
		Cert = $Cert
		FilePath = $CertFile
		Type = "CERT"
		Force = $Force
		NoClobber = $NoClobber
	}

	if ((!$NoClobber -or $Force) -or !(Test-Path $CertFile -PathType Leaf -ErrorAction Ignore))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Exporting certificate '$Domain.cer'"
		Export-Certificate @ExportParams | Out-Null
	}
	else
	{
		Write-Warning -Message "Certificate '$Domain.cer' not exported, target file already exists"
	}

	# Add public key to trusted root to trust this certificate locally, if it's not already there
	if (!(Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq "CN=$Domain" }))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Trusting certificate '$Domain.cer' locally"
		Import-Certificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
	}

	Write-Information -Tags "Project" -MessageData "INFO: Using certificate with thumbprint $($Cert.Thumbprint)"

	# Write-Information -Tags "Project" -MessageData "INFO: Enabling PowerShell remoting"
	# NOTE: We do manual configuration without Enable-PSRemoting
	# Enable-PSRemoting

	# NOTE: Will not work because certificate is self signed
	# Set-WSManQuickConfig -UseSSL

	# Configure HTTPS listener
	# NOTE: WinRM service must be running at this point
	Write-Information -Tags "Project" -MessageData "INFO: Starting WS-Management service"
	Get-Service -Name WinRM | Set-Service -StartupType Automatic
	Start-Service -Name WinRM

	try
	{
		$HTTPS = Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address = "*"; Transport = "HTTPS" }
	}
	catch
	{
		$HTTPS = $null
		Write-Information -Tags "Project" -MessageData "INFO: No HTTPS listener exists"
	}
	finally
	{
		$CountHTTPS = ($HTTPS | Measure-Object).Count
	}

	if ($CountHTTPS -gt 1)
	{
		Write-Error -Category NotImplemented -TargetObject $HTTPS -Message "Multiple HTTPS listeners exist"
	}
	elseif ($CountHTTPS -eq 1)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Setting existing HTTPS listener"
		Set-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
			-ValueSet @{ Hostname = $Domain; Enabled = "true"; CertificateThumbprint = $Cert.Thumbprint } | Out-Null
	}
	else
	{
		Write-Information -Tags "Project" -MessageData "INFO: Adding new HTTPS listener"
		New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -Hostname $Domain -CertificateThumbPrint $Cert.Thumbprint -Force:$Force | Out-Null
	}

	# NOTE: Other service configuration can be set\confirmed here
	Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value "false"
	Set-Item WSMan:\localhost\Service\Auth\Certificate -Value "true"
	Set-Item WSMan:\localhost\Service\AllowRemoteAccess -Value "true"

	# Remove all custom made session configurations
	Write-Information -Tags "Project" -MessageData "INFO: Removing non default session configurations"
	Get-PSSessionConfiguration -Force |	Where-Object -Property Name -NotLike "Microsoft*" |
	Unregister-PSSessionConfiguration -NoServiceRestart -Force

	# Register repository specific session configuration
	Write-Information -Tags "Project" -MessageData "INFO: Registering repository specific session configuration, please wait..."
	# TODO: This or something earlier restarts WinRM service which is not needed at this point
	Register-PSSessionConfiguration -Path $ProjectRoot\Config\Windows\FirewallSession.pssc `
		-Name "FirewallSession" -ProcessorArchitecture amd64 -ThreadApartmentState Unknown `
		-ThreadOptions UseCurrentThread -AccessMode Remote -NoServiceRestart -Force `
		-MaximumReceivedDataSizePerCommandMB 50 -MaximumReceivedObjectSizeMB 10
	#-RunAsCredential $RemoteCredential -UseSharedProcess -NoServiceRestart -SecurityDescriptorSddl `
	#-SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"

	# Remove the Deny_All setting from the security descriptor of the affected session
	Write-Information -Tags "Project" -MessageData "INFO: Enabling repository specific session configuration"
	Enable-PSSessionConfiguration -Name FirewallSession -NoServiceRestart -Force

	# Remove all HTTP listeners
	Write-Information -Tags "Project" -MessageData "INFO: Removing all HTTP listeners"
	Get-ChildItem WSMan:\localhost\Listener | Where-Object -Property Keys -EQ "Transport=HTTP" | Remove-Item -Recurse

	# Disable unused default session configurations
	Write-Information -Tags "Project" -MessageData "INFO: Disabling unneeded default session configurations"
	# Disable-PSSessionConfiguration -Name Microsoft.PowerShell
	Disable-PSSessionConfiguration -Name Microsoft.PowerShell32
	Disable-PSSessionConfiguration -Name Microsoft.PowerShell.Workflow

	Write-Information -Tags "Project" -MessageData "INFO: Restarting WS-Management service"
	Restart-Service -Name WinRM

	try
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on localhost '$Domain'"
		Test-WSMan -UseSSL -ComputerName $Domain -ErrorAction Stop
	}
	catch
	{
		Write-Warning -Message "HTTPS on localhost failed, trying again with Enter-PSSession and 'SkipCACheck'"
		$SessionOptions = New-PSSessionOption -SkipCACheck
		Enter-PSSession -UseSSL -ComputerName $Domain -ConfigurationName FirewallSession -SessionOption $SessionOptions
		Exit-PSSession
	}

	# Show configured session configuration
	Write-Information -Tags "Project" -MessageData "INFO: Showing all enabled session configurations (short version)"
	Get-PSSessionConfiguration | Where-Object -Property Enabled -EQ True |
	Select-Object -Property Name, Enabled, PSVersion, Architecture, SupportsOptions, lang, AutoRestart, RunAsUser, RunAsPassword, Permission
	# Get-PSSessionConfiguration | Where-Object -Property Enabled -EQ True | Select-Object *

	# Show WinRM configuration
	Write-Information -Tags "Project" -MessageData "INFO: Showing configured listeners"
	Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate

	Write-Information -Tags "Project" -MessageData "INFO: Showing server configuration"
	Get-WSManInstance -ResourceURI winrm/config/Service

	Write-Information -Tags "Project" -MessageData "INFO: Showing server authentication"
	Get-WSManInstance -ResourceURI winrm/config/Service/Auth

	Write-Information -Tags "Project" -MessageData "INFO: Showing server default ports"
	Get-WSManInstance -ResourceURI winrm/config/Service/DefaultPorts

	if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose"))
	{
		Write-Verbose -Message "Showing shell configuration"
		Get-Item WSMan:\localhost\Shell\*

		Write-Verbose -Message "Showing plugin configuration"
		Get-Item WSMan:\localhost\Plugin\*

		# All in one alternative
		# winrm get winrm/config
	}
}
else
{
	# Management machine
	if ([string]::IsNullOrEmpty($CertFile))
	{
		$CertFile = "$CertPath\$Domain.cer"
	}

	$Cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	if (($Cert | Measure-Object).Count -gt 1)
	{
		# TODO: Search by thumbprint from CertFile if specified or implement parameter for Cert object
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates match"
		return
	}

	if ($Cert) # if (Cert -eq 1)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Certificate for computer '$Domain' already exists"
	}
	elseif (Test-Path $CertFile -PathType Leaf -ErrorAction Ignore)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Importing certificate '$CertFile'"
		$Cert = Import-Certificate -FilePath $CertFile -CertStoreLocation "Cert:\LocalMachine\Root"
	}
	else
	{
		Write-Error -Category ObjectNotFound -TargetObject $CertFile -Message "Specified certificate file was not found '$CertFile'"
		return
	}

	# NOTE: Other client configuration can be set\confirmed here
	Set-Item WSMan:\localhost\Client\Auth\Certificate -Value "true"
	Set-Item WSMan:\localhost\Client\AllowUnencrypted -Value "false"

	# TODO: WinRM protocol options (one of your networks is public)
	# Set-WSManInstance -ResourceURI winrm/config -ValueSet @{ MaxTimeoutms = 3000 }

	Write-Information -Tags "Project" -MessageData "INFO: Contacting computer '$Domain'"

	if (Test-NetConnection -ComputerName $Domain -Port 5986 -InformationLevel Quiet -EA Ignore)
	{
		# Test remote configuration
		$RemoteCredential = Get-Credential -Message "Credentials are required to access computer '$Domain'"
		# NOTE: This fails, see commend in Test-Credential.ps1 module script
		Test-Credential $RemoteCredential -Context Machine -Domain $Domain -EA "Continue"

		try
		{
			Write-Information -Tags "Project" -MessageData "INFO: Using certificate with thumbprint $($Cert.Thumbprint)"
			Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on computer '$Domain'"
			Test-WSMan -UseSSL -ComputerName $Domain -Credential $RemoteCredential -Authentication "Default"
			# -CertificateThumbprint $Cert.Thumbprint -ApplicationName -Port
		}
		catch
		{
			# Eneter remote session
			Write-Warning -Message "HTTPS on '$Domain' failed, trying again with Enter-PSSession"
			# $SessionOptions = New-PSSessionOption -SkipCACheck
			Enter-PSSession -UseSSL -ComputerName $Domain -Credential $RemoteCredential `
				-ConfigurationName FirewallSession # -SessionOption $SessionOptions
			Exit-PSSession
		}
	}
	elseif (Test-Connection -ComputerName $Domain -Count 2 -Quiet -EA Ignore)
	{
		Write-Error -Category ConnectionError -TargetObject $Domain -Message "WinRM listener on computer $Domain does not respond"
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $Domain -Message "Computer $Domain does not respond"
	}

	Write-Information -Tags "Project" -MessageData "INFO: Showing client configuration"
	Get-WSManInstance -ResourceURI winrm/config/Client

	Write-Information -Tags "Project" -MessageData "INFO: Showing client authentication"
	Get-WSManInstance -ResourceURI winrm/config/Client/Auth

	Write-Information -Tags "Project" -MessageData "INFO: Showing client default ports"
	Get-WSManInstance -ResourceURI winrm/config/Client/DefaultPorts

	if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose"))
	{
		Write-Verbose -Message "Showing shell configuration"
		Get-Item WSMan:\localhost\Shell\*

		Write-Verbose -Message "Showing plugin configuration"
		Get-Item WSMan:\localhost\Plugin\*

		# All in one alternative
		# winrm get winrm/config
	}

	# Client setting
	# Write-Information -Tags "Project" -MessageData "INFO: Showing client certificate configuration"
	# Get-Item WSMan:\localhost\ClientCertificate\*
}

Write-Information -Tags "Project" -MessageData "INFO: All operation completed successfully"
