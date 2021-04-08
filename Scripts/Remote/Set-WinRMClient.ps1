
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
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote computer, use Connect-WSMan and New-WSManSessionOption
HACK: Remote HTTPS with "localhost" name in addition to local machine name
TODO: Authenticate users using certificates instead of or optionally in addition to credential object
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Check parameter naming convention
TODO: CIM testing
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Server settings are missing for client
TODO: Not all optional settings are configured

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
# $VerbosePreference = "Continue"

# NOTE: if needed for troubleshooting set "Any" to RemoteAddress parameter
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

Write-Verbose -Message "[$ThisModule] Configuring WinRM client authentication options"

# Valid authentication for both client and server
# NOTE: HTTP traffic by default only allows messages encrypted with the Negotiate or Kerberos SSP
[hashtable] $AuthenticationOptions = @{
	# The user name and password are sent in clear text.
	# Basic authentication cannot be used with domain accounts
	# The default value is true.
	Basic = $false
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

# NOTE: Not assuming WinRM responds, contact localhost
if (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain)
{
	$AuthenticationOptions["Kerberos"] = $true
}

if ($Protocol -eq "HTTP")
{
	$AuthenticationOptions["Certificate"] = $false
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

	if ($Domain -ne ([System.Environment]::MachineName))
	{
		# The TrustedHosts item can contain a comma-separated list of computer names,
		# IP addresses, and fully-qualified domain names. Wildcards are permitted.
		# Affects all users of the computer.
		# TODO: Add instead of set
		$ClientOptions["TrustedHosts"] = $Domain
	}
	else
	{
		$ClientOptions["TrustedHosts"] = ""
	}
}

Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"

# TODO: WinRM protocol options (one of your networks is public) -SkipNetworkProfileCheck?
[hashtable] $ConfigOptions = @{
	# Specifies the maximum time-out, in milliseconds, that can be used for any request other than Pull requests.
	# The default value is 60000.
	MaxTimeoutms = $PSSessionOption.OperationTimeout.TotalMilliseconds
}

try
{
	Set-WSManInstance -ResourceURI winrm/config -ValueSet $ConfigOptions | Out-Null
}
catch [System.InvalidOperationException]
{
	if ([regex]::IsMatch($_.Exception.Message, "either Domain or Private"))
	{
		Write-Error -Category InvalidOperation -TargetObject $ConfigOptions -ErrorAction "Continue" `
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
			# TODO: Prompt to disable Hyper-V here and Stop-Computer
			Write-Warning -Message "To resolve this problem, uninstall Hyper-V or disable unneeded virtual switches and try again"
		}

		# TODO: Else prompt to disable virtual switches
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
	& $PSScriptRoot\Install-SslCertificate.ps1 @SSLCertParams | Out-Null
}

Write-Verbose -Message "[$ThisModule] Restarting WS-Management service"
Restart-Service -InputObject $WinRMService
$Seconds = 4

for ($Repeat = 1; $Repeat -le 10; ++$Repeat)
{
	Write-Verbose -Message "[$ThisScript] Waiting $Seconds seconds for WinRM service to restart" -Verbose
	Start-Sleep -Seconds $Seconds

	if ((Get-Service -Name WinRM).Status -eq "Running")
	{
		break
	}

	$Seconds = 2
}

if (!$SkipTestConnection)
{
	$WSManParams = @{
		Authentication = "Default"
	}

	if (($Domain -ne ([System.Environment]::MachineName)) -or ($Protocol -ne "HTTP"))
	{
		$WSManParams["ComputerName"] = $Domain
		# TODO: Already defined in ProjectSettings.ps1
		$WSManParams["Credential"] = Get-Credential -Message "Credentials are required to access host '$Domain'"
	}

	if ($Protocol -ne "HTTP")
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on computer '$Domain'"
		# TODO: -CertificateThumbprint $Cert.Thumbprint -ApplicationName -Port
		Test-WSMan -UseSSL @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}

	if ($Protocol -ne "HTTPS")
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTP on computer '$Domain'"
		Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}
}

# Remove WinRM predefined compatibility rules
Get-NetFirewallRule -Group "@FirewallAPI.dll,-30252" -PolicyStore PersistentStore | Remove-NetFirewallRule
Write-Information -Tags "Project" -MessageData "INFO: WinRM client configuration was successful"

# Update-Log
