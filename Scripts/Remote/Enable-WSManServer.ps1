
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

.GUID 4c91358a-6a2e-424a-85a7-7b0419284216

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Configure WinRM server

.DESCRIPTION
Configures local machine to accept remote CIM and PowerShell requests using WS-Management.
Enabling PS remoting includes starting the WinRM service
Setting the startup type for the WinRM service to Automatic
Creating default and custom session configurations
Creating listeners for HTTP and\or HTTPS connections

.PARAMETER Protocol
Specifies listener protocol to HTTP, HTTPS or both.
By default only HTTPS is configured.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default new self signed certifcate is made if none exists.

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER SkipTestConnection
Skip testing configuration on completion.
By default connection and authentication request on local WinRM server is performed.

.PARAMETER ShowConfig
Display WSMan server configuration on completion

.PARAMETER Force
If specified, overwrites an existing certificate file,
unless it has the Read-only attribute set.

.EXAMPLE
PS> .\Enable-WSManServer.ps1

Configures server machine to accept remote commands using using SSL.
If there is no server certificate a new one self signed is made and put into trusted root.

.EXAMPLE
PS> .\Enable-WSManServer.ps1 -CertFile C:\Cert\Server2.pfx -Protocol Any

Configures server machine to accept remote commands using using either HTTPS or HTTP.
Client will authenticate with specified certificate for HTTPS.

.EXAMPLE
PS> .\Enable-WSManServer.ps1 -Protocol HTTP -ShowConfig -SkipTestConnection

Configures server machine to accept remote commands using HTTP,
when done WinRM server configuration is shown and WinRM test is not performed.

.INPUTS
None. You cannot pipe objects to Enable-WSManServer.ps1

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
TODO: This script must be part of Ruleset.Initialize module
NOTE: Following will be set by something in this script, it prevents remote UAC
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: To test, configure or query remote use Connect-WSMan and New-WSManSessionOption
HACK: Remote HTTPS with localhost name possibility in addition to local machine name
TODO: Authenticate users using certificates instead of or optionally in addition to credential object
TODO: Test-Certificate before importing, mandatory if -CertFile is specified
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Needs polish and converting some info streams into verbose or debug
TODO: Check parameter naming convention
TODO: CIM testing
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Client settings are missing for server

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

	[Parameter(ParameterSetName = "File")]
	[ValidateScript( { $_.EndsWith(".pfx") } )]
	[string] $CertFile,

	[Parameter(ParameterSetName = "ThumbPrint")]
	[string] $CertThumbPrint,

	[Parameter()]
	[switch] $SkipTestConnection,

	[Parameter()]
	[switch] $ShowConfig,

	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -PolicyStore ([System.Environment]::MachineName)
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$CertPath = "$ProjectRoot\Exports"
$Domain = [System.Environment]::MachineName

# Specify acceptable client authentication methods
[hashtable] $AuthenticationOptions = @{
	# The user name and password are sent in clear text.
	# Basic authentication cannot be used with domain accounts
	# The default value is true.
	Basic = $true
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

if ([string]::IsNullOrEmpty($CertFile))
{
	# Search default file name location
	$CertFile = "$CertPath\$Domain.pfx"
	$ExportFile = "$CertPath\$Domain.cer"

	# Search personal store for certificate first
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	if (!$Cert)
	{
		$Cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
			$_.Subject -eq "CN=$Domain"
		}
	}

	if ($CertThumbPrint)
	{
		if ($Cert)
		{
			$Cert = $Cert | Where-Object -Property Thumbprint -EQ $CertThumbPrint
		}

		if (!$Cert)
		{
			Write-Error -Category NotImplemented -TargetObject $Cert -Message "Certificate with specified thumbprint not found '$CertThumbPrint'"
		}
	}

	if (($Cert | Measure-Object).Count -eq 1)
	{
		if (Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain -AllowUntrustedRoot)
		{
			if ($Cert.HasPrivateKey)
			{
				Write-Verbose -Message "[$ThisScript] Using existing certificate '$($Cert.thumbprint)'"
			}
			else
			{
				Write-Error -Category OperationStopped -TargetObject $Cert -Message "Private key missing, please specify thumbprint"
			}
		}
		else
		{
			Write-Error -Category SecurityError -TargetObject $Cert -Message "Verification failed for certificate '$($Cert.thumbprint)'"
		}
	}
	elseif ($Cert)
	{
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates exist for host '$Domain', please specify thumbprint"
	}
	elseif (Test-Path $CertFile -PathType Leaf -ErrorAction Ignore)
	{
		# Import certificate file from default location
		$CertPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (
			"$Domain.pfx", (Read-Host -AsSecureString -Prompt "Enter certificate password"))

		$Cert = Import-PfxCertificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My `
			-Password $CertPassword.Password -Exportable

		if (($Cert.Subject -ne "CN=$Domain") -or
			($CertThumbPrint -and ($Cert.thumbprint -ne $CertThumbPrint)) -or
			!(Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain -AllowUntrustedRoot))
		{
			# Undo import operation
			Get-ChildItem Cert:\LocalMachine\My |
			Where-Object { $_.Thumbprint -eq $Cert.thumbprint } | Remove-Item
			Write-Error -Category SecurityError -TargetObject $Cert -Message "Certificate verification from default location failed"
		}

		Write-Verbose -Message "[$ThisScript] Using certificate from default location '$($Cert.thumbprint)'"
	}
	else
	{
		$Date = Get-Date
		Write-Information -Tags "Project" -MessageData "INFO: Creating new certificate"

		# TODO: -Signer -KeySpec -HashAlgorithm -Subject "localhost"
		$Cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation Cert:\LocalMachine\My `
			-FriendlyName "RemoteFirewall" -KeyAlgorithm RSA -KeyDescription "PSRemotingKey" `
			-KeyFriendlyName "RemoteFirewall" -KeyLength 2048 -Type SSLServerAuthentication `
			-KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy ExportableEncrypted `
			-NotBefore $Date -NotAfter $Date.AddMonths(6)

		Write-Verbose -Message "[$ThisScript] Using new certificate '$($Cert.thumbprint)'"
	}
}
elseif (Test-Path $CertFile -PathType Leaf -ErrorAction Ignore)
{
	# Import certificate file from custom location
	$CertPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (
		"$Domain.pfx", (Read-Host -AsSecureString -Prompt "Enter certificate password"))

	$Cert = Import-PfxCertificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My `
		-Password $CertPassword.Password -Exportable

	# Custom external certificate should be not self signed
	if (Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain)
	{
		Write-Verbose -Message "[$ThisScript] Using certificate from custom location '$($Cert.thumbprint)'"
	}
	else
	{
		# Undo import operation
		Get-ChildItem Cert:\LocalMachine\My |
		Where-Object { $_.Thumbprint -eq $Cert.thumbprint } | Remove-Item
		Write-Error -Category SecurityError -TargetObject $Cert -Message "Certificate verification from custom location failed"
	}
}
else
{
	Write-Error -Category ObjectNotFound -TargetObject $CertFile -Message "Specified certificate file was not found '$CertFile'"
}

# Export self signed, existing certificate from store or imported PFX
if (Test-Path $ExportFile -PathType Leaf -ErrorAction Ignore)
{
	if ($Force)
	{
		# TODO: Test, it should fail for readonly file
		Write-Warning -Message "Overriding certificate file '$ExportFile'"
		Export-Certificate -Cert $Cert -FilePath $ExportFile -Type CERT -Force | Out-Null
	}
	else
	{
		Write-Warning -Message "Certificate '$Domain.cer' not exported, target file already exists"
	}
}
else
{
	Write-Information -Tags "Project" -MessageData "INFO: Exporting certificate '$Domain.cer'"
	Export-Certificate -Cert $Cert -FilePath $ExportFile -Type CERT | Out-Null
}

if (!$Cert.Verify())
{
	# TODO: Should be verified or singed by custom key
	# Add public key to trusted root to trust this certificate locally
	Write-Warning -Message "Trusting certificate '$Domain.cer'"
	Import-Certificate -FilePath $ExportFile -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
}

# WinRM service must be running at this point
Write-Verbose -Message "[$ThisScript] Starting WS-Management service"
Get-Service -Name WinRM | Set-Service -StartupType Automatic
Start-Service -Name WinRM

# NOTE: Not assuming WinRM responds, contact localhost
if (Get-CimInstance -Namespace "root\cimv2" `
		-Class Win32_ComputerSystem -Property PartOfDomain |
	Select-Object -ExpandProperty PartOfDomain)
{
	# TODO: Adjust authentication method if computer in domain
	$AuthenticationOptions["Basic"] = $false
	$AuthenticationOptions["Kerberos"] = $true
}

# Remove all custom made session configurations
Write-Verbose -Message "[$ThisScript] Removing non default session configurations"
Get-PSSessionConfiguration -Force |	Where-Object -Property Name -NotLike "Microsoft*" |
Unregister-PSSessionConfiguration -NoServiceRestart -Force

# Disable unused built in session configurations
Write-Verbose -Message "[$ThisScript] Disabling unneeded default session configurations"
Disable-PSSessionConfiguration -Name Microsoft.PowerShell32
Disable-PSSessionConfiguration -Name Microsoft.PowerShell.Workflow

# Enable default configuration
Write-Verbose -Message "[$ThisScript] Configuring WinRM server listener and session options"
Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
Enable-PSSessionConfiguration -Name Microsoft.PowerShell -NoServiceRestart -Force

if (($Protocol -eq "HTTPS") -or ($Protocol -eq "Any"))
{
	Write-Verbose -Message "[$ThisScript] Enabling session configurations"

	# Register repository specific session configuration
	# [Microsoft.WSMan.Management.WSManConfigContainerElement]
	$WSManEntry = Register-PSSessionConfiguration -Path $ProjectRoot\Config\RemoteFirewall.pssc `
		-Name "RemoteFirewall" -ProcessorArchitecture amd64 -ThreadApartmentState Unknown `
		-ThreadOptions UseCurrentThread -AccessMode Remote -NoServiceRestart -Force `
		-MaximumReceivedDataSizePerCommandMB 50 -MaximumReceivedObjectSizeMB 10
	#-RunAsCredential $RemoteCredential -UseSharedProcess `
	#-SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"

	Write-Information -Tags "Project" -MessageData "INFO: Session configuration '$($WSManEntry.Name)' registered successfully"

	# Remove the Deny_All setting from the security descriptor of the affected session
	# The local computer must include session configurations for remote commands.
	# Remote users use these session configurations whenever a remote command does not include the ConfigurationName parameter
	Enable-PSSessionConfiguration -Name RemoteFirewall -NoServiceRestart -Force

	Write-Verbose -Message "[$ThisScript] Configuring WinRM HTTPS server listener options"

	# Add new HTTPS listener
	New-Item -Path WSMan:\localhost\listener -Transport HTTPS -Address * -Hostname $Domain `
		-CertificateThumbPrint $Cert.Thumbprint -Force | Out-Null

	if ($Protocol -eq "HTTPS")
	{
		# Set-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
		# 	-ValueSet @{ Hostname = $Domain; Enabled = "true"; CertificateThumbprint = $Cert.Thumbprint } | Out-Null

		# Disable HTTP listener created by Microsoft.PowerShell session configuration
		Write-Verbose -Message "[$ThisScript] Disabling all HTTP listeners"
		Set-WSManInstance -ResourceURI winrm/config/listener -ValueSet @{ Enabled = $false } `
			-SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null
	}
}

Write-Verbose -Message "[$ThisScript] Configuring WinRM server authentication options"

# TODO: Test registry fix for cases when Negotiate is disabled
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisScript] Configuring WinRM server options"
[hashtable] $ServerOptions = @{
	AllowRemoteAccess = $true

	# Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
	# The default is 120 seconds.
	MaxPacketRetrievalTimeSeconds = 10

	# Specifies the idle time-out in milliseconds between Pull messages.
	# The default is 60000.
	EnumerationTimeoutms = 6000
}

if ($Protocol -eq "HTTPS")
{
	$ServerOptions["AllowUnencrypted"] = $false
}
else
{
	# Allows the client computer to request unencrypted traffic.
	# The default value is false
	$ServerOptions["AllowUnencrypted"] = $true
}

Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null

Write-Verbose -Message "[$ThisScript] Restarting WS-Management service"
Restart-Service -Name WinRM

$ErrorActionPreference = "Continue"

if (!$SkipTestConnection)
{
	if (($Protocol -eq "HTTPS") -or ($Protocol -eq "Any"))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on localhost '$Domain'"
		Test-WSMan -UseSSL -ComputerName $Domain -Authentication "Default" |
		Select-Object ProductVendor, ProductVersion | Format-List
	}

	if (($Protocol -eq "HTTP") -or ($Protocol -eq "Any"))
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTP on localhost '$Domain'"
		Test-WSMan -ComputerName $Domain -Authentication "Default" |
		Select-Object ProductVendor, ProductVersion | Format-List
	}
}

if ($ShowConfig)
{
	# NOTE: Beginning in PowerShell 6, it is no longer required to include the Property parameter for ExcludeProperty to work.

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
