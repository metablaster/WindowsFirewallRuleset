
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

.PARAMETER CertFile
Optionally specify custom certificate file.
By default certificate store is searched for certificate with CN entry set to value specified by
-Domain parameter.
If not found, default repository location (\Exports) is searched for DER encoded CER file,
Certificate file must be DER encoded CER file

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER SkipTestConnection
Skip testing configuration on completion.
By default connection and authentication request on remote WinRM server is performed.

.PARAMETER ShowConfig
Display WSMan server configuration on completion

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
TODO: This script must be part of Ruleset.Initialize module
NOTE: Following will be set by something in this script, it prevents remote UAC
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote use Connect-WSMan and New-WSManSessionOption
HACK: Remote HTTPS with localhost name possibility in addition to local machine name
TODO: Authenticate users using certificates instead of or optionally in addition to credential object
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Needs polish and converting some info streams into verbose or debug
TODO: Check parameter naming convention
TODO: CIM testing
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Server settings are missing for client
TODO: Not all optional settings are configured

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

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
[OutputType([void], [System.Xml.XmlElement])]
param (
	[Parameter()]
	[ValidateSet("HTTP", "HTTPS", "Any")]
	[string] $Protocol = "HTTPS",

	[Parameter(Mandatory = $true)]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter(ParameterSetName = "File")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "CertThumbPrint")]
	[string] $CertThumbPrint,

	[Parameter()]
	[switch] $SkipTestConnection,

	[Parameter()]
	[switch] $ShowConfig
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
Initialize-Project -Strict

$ErrorActionPreference = "Stop"

$WinRMService = Get-Service -Name WinRM
# NOTE: WinRM service must be running at this point, handled by ProjectSettings.ps1

if ($WinRMService.StartType -ne "Automatic")
{
	Write-Information -Tags "User" -MessageData "INFO: Setting WS-Management service to automatic startup"
	Set-Service -InputObject $WinRMService -StartupType Automatic
}

if ($WinRMService.Status -ne "Running")
{
	Write-Information -Tags "User" -MessageData "INFO: Starting WS-Management service"
	Start-Service -InputObject $WinRMService
}

Write-Information -Tags "Project" -MessageData "INFO: Configuring WinRM service"

# Valid authentication for both client and server
[hashtable] $AuthenticationOptions = @{
	# The user name and password are sent in clear text.
	# Basic authentication cannot be used with domain accounts
	# The default value is true.
	Basic = $true
	# Challenge-response scheme that uses a server-specified data string for the challenge.
	# Supported by both HTTP and HTTPS
	# The WinRM service does not accept Digest authentication.
	# The default value is true.
	Digest = $false
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
	Certificate = $true
	# Allows the client to use Credential Security Support Provider (CredSSP) authentication.
	# The default value is false.
	CredSSP = $false
}

# Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"

# TODO: WinRM protocol options (one of your networks is public) -SkipNetworkProfileCheck?
[hashtable] $ConfigOptions = @{
	# Specifies the maximum time-out, in milliseconds, that can be used for any request other than Pull requests.
	# The default value is 60000.
	MaxTimeoutms = $PSSessionOption.OperationTimeout.TotalMilliseconds
}

# Set-WSManInstance -ResourceURI winrm/config -ValueSet $ConfigOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM client authentication options"

# NOTE: Not assuming WinRM responds, contact localhost
if (Get-CimInstance -Namespace "root\cimv2" `
		-Class Win32_ComputerSystem -Property PartOfDomain |
	Select-Object -ExpandProperty PartOfDomain)
{
	# TODO: Adjust authentication method if computer in domain
	$AuthenticationOptions["Basic"] = $false
	$AuthenticationOptions["Kerberos"] = $true
}

try
{
	# NOTE: If this fails, registry fix must precede all other authentication edits
	Set-Item WSMan:\localhost\Client\Auth\Negotiate -Value $AuthenticationOptions["Negotiate"]
}
catch
{
	Write-Warning -Message "Enabling 'Negotiate' authentication failed, enabling trough registry"
	Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ -Name auth_negotiate -Value (
		[int32] ($AuthenticationOptions["Negotiate"] -eq $true))
}

Set-WSManInstance -ResourceURI winrm/config/client/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM client options"
[hashtable] $ClientOptions = @{
	# Specifies the extra time in milliseconds that the client computer waits to accommodate for network delay time.
	# The default value is 5000 milliseconds.
	NetworkDelayms = 1000
}

if ($Protocol -eq "HTTPS")
{
	$ClientOptions["AllowUnencrypted"] = $false

	$ClientOptions["TrustedHosts"] = ""
}
else
{
	# Allows the client computer to request unencrypted traffic.
	# The default value is false
	$ClientOptions["AllowUnencrypted"] = $true

	# The TrustedHosts item can contain a comma-separated list of computer names,
	# IP addresses, and fully-qualified domain names. Wildcards are permitted.
	# Affects all users of the computer.
	# TODO: Add instead of set
	$ClientOptions["TrustedHosts"] = $Domain
}

Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null

# SSL certificate
[hashtable] $SSLCertParams = @{
	Target = "Client"
	Domain = $Domain
}

if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
elseif (![string]::IsNullOrEmpty($CertThumbPrint)) { $SSLCertParams["CertThumbPrint"] = $CertThumbPrint }
& $PSScriptRoot\Install-SslCertificate.ps1 @SSLCertParams | Out-Null

if (!$SkipTestConnection)
{
	# TODO: Already defined in ProjectSettings.ps1
	$RemoteCredential = Get-Credential -Message "Credentials are required to access host '$Domain'"

	if (($Protocol -eq "HTTPS") -or ($Protocol -eq "Any"))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on computer '$Domain'"
		Test-WSMan -UseSSL -ComputerName $Domain -Credential $RemoteCredential -Authentication "Default" |
		Select-Object ProductVendor, ProductVersion | Format-List
		# TODO: -CertificateThumbprint $Cert.Thumbprint -ApplicationName -Port
	}

	if (($Protocol -eq "HTTP") -or ($Protocol -eq "Any"))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTP on computer '$Domain'"
		Test-WSMan -ComputerName $Domain -Credential $RemoteCredential -Authentication "Default" |
		Select-Object ProductVendor, ProductVersion | Format-List
	}
}

Write-Information -Tags "Project" -MessageData "INFO: WinRM client configuration was successful"

if ($ShowConfig)
{
	# NOTE: Beginning in PowerShell 6, it is no longer required to include the Property parameter for ExcludeProperty to work.

	# winrm get winrm/config/client
	Write-Information -Tags "Project" -MessageData "INFO: Showing client configuration"
	Get-WSManInstance -ResourceURI winrm/config/Client |
	Select-Object -ExcludeProperty cfg, Auth, DefaultPorts

	# winrm get winrm/config/client/auth
	Write-Information -Tags "Project" -MessageData "INFO: Showing client authentication"
	Get-WSManInstance -ResourceURI winrm/config/Client/Auth | Select-Object -ExcludeProperty cfg

	# winrm get winrm/config/client/defaultports
	Write-Information -Tags "Project" -MessageData "INFO: Showing client default ports"
	Get-WSManInstance -ResourceURI winrm/config/Client/DefaultPorts | Select-Object -ExcludeProperty cfg

	if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose"))
	{
		Write-Verbose -Message "[$ThisModule] Showing shell configuration"
		Get-Item WSMan:\localhost\Shell\*

		Write-Verbose -Message "[$ThisModule] Showing plugin configuration"
		Get-Item WSMan:\localhost\Plugin\*
	}

	# TODO: User authentication certificate
	# Write-Information -Tags "Project" -MessageData "INFO: Showing client certificate configuration"
	# Get-Item WSMan:\localhost\ClientCertificate\*
}
