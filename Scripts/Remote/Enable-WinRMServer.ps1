
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
Configure WinRM server for CIM and PowerShell remoting

.DESCRIPTION
Configures local machine to accept remote CIM and PowerShell requests using WS-Management.
Enabling PS remoting includes starting the WinRM service
Setting the startup type for the WinRM service to Automatic
Creating default and custom session configurations
Creating listeners for HTTPS or\and HTTPS connections

.PARAMETER Protocol
Specifies listener protocol to HTTP, HTTPS or both.
By default only HTTPS is configured.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default new self signed certifcate is made and trusted if no suitable certificate exists.
This must be PFX file.

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER SkipTestConnection
Skip testing configuration on completion.
By default connection and authentication request on local WinRM server is performed.

.PARAMETER ShowConfig
Display WSMan server configuration on completion

.PARAMETER Force
If specified, overwrites an existing exported certificate file,
unless it has the Read-only attribute set.
TODO: see other places where -Force is used too.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1

Configures server machine to accept remote commands using using SSL.
If there is no server certificate a new one self signed is made and put into trusted root.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1 -CertFile C:\Cert\Server2.pfx -Protocol Any

Configures server machine to accept remote commands using using either HTTPS or HTTP.
Client will authenticate with specified certificate for HTTPS.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1 -Protocol HTTP -ShowConfig -SkipTestConnection

Configures server machine to accept remote commands using HTTP,
when done WinRM server configuration is shown and WinRM test is not performed.

.INPUTS
None. You cannot pipe objects to Enable-WinRMServer.ps1

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
HACK: Set-WSManInstance may fail with public profile, as a workaround use Set-WSManQuickConfig,
rerun script twice refusing Set-WSManQuickConfig prompt next time.
NOTE: Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
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
TODO: Client settings are missing for server
TODO: Not all optional settings are configured

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configuration_files

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration

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

	[Parameter(ParameterSetName = "File")]
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

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
# $VerbosePreference = "Continue"
$Domain = [System.Environment]::MachineName

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

<# MSDN: The Enable-PSRemoting cmdlet performs the following operations:
Runs the Set-WSManQuickConfig cmdlet, which performs the following tasks:
1. Starts the WinRM service.
2. Sets the startup type on the WinRM service to Automatic.
3. Creates a listener to accept requests on any IP address.
4. Enables a firewall exception for WS-Management communications.
5. Creates the simple and long name session endpoint configurations if needed.
6. Enables all session configurations.
7. Changes the security descriptor of all session configurations to allow remote access.
Restarts the WinRM service to make the preceding changes effective.
#>
Write-Information -Tags "Project" -MessageData "INFO: Configuring WinRM service"

# Remove all custom made session configurations
Write-Verbose -Message "[$ThisModule] Removing non default session configurations"
Get-PSSessionConfiguration -Force |	Where-Object -Property Name -NotLike "Microsoft*" |
Unregister-PSSessionConfiguration -NoServiceRestart -Force

# Disable unused built in session configurations
Write-Verbose -Message "[$ThisModule] Disabling unneeded default session configurations"
Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force

# Enable default configuration
Write-Verbose -Message "[$ThisModule] Configuring WinRM server listener and session options"
Set-WSManQuickConfig -SkipNetworkProfileCheck -Force | Out-Null
# TODO: Set security descriptor or run Enable-PSRemoting
Enable-PSSessionConfiguration -Name Microsoft.PowerShell -NoServiceRestart -Force -SkipNetworkProfileCheck | Out-Null

Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
if ($Protocol -ne "HTTPS")
{
	New-WSManInstance -SelectorSet @{Address = "*"; Transport = "HTTP" } `
		-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null
}

if ($Protocol -ne "HTTP")
{
	# SSL certificate
	[hashtable] $SSLCertParams = @{
		Target = "Server"
		Force = $Force
	}

	if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
	elseif (![string]::IsNullOrEmpty($CertThumbPrint)) { $SSLCertParams["CertThumbPrint"] = $CertThumbPrint }
	$Cert = & $PSScriptRoot\Install-SslCertificate.ps1 @SSLCertParams

	Write-Verbose -Message "[$ThisModule] Enabling session configurations"
	# Register repository specific session configuration
	# [Microsoft.WSMan.Management.WSManConfigContainerElement]
	$WSManEntry = Register-PSSessionConfiguration -Path $ProjectRoot\Config\RemoteFirewall.pssc `
		-Name "RemoteFirewall" -ProcessorArchitecture amd64 -ThreadApartmentState Unknown `
		-ThreadOptions UseCurrentThread -AccessMode Remote -NoServiceRestart -Force `
		-MaximumReceivedDataSizePerCommandMB 50 -MaximumReceivedObjectSizeMB 10
	# -RunAsCredential $RemoteCredential -UseSharedProcess `
	# -SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"

	Write-Verbose -Message "[$ThisModule] Session configuration '$($WSManEntry.Name)' registered successfully"

	# Remove the Deny_All setting from the security descriptor of the affected session
	# The local computer must include session configurations for remote commands.
	# Remote users use these session configurations whenever a remote command does not include the ConfigurationName parameter
	Enable-PSSessionConfiguration -Name RemoteFirewall -NoServiceRestart -Force -SkipNetworkProfileCheck | Out-Null

	Write-Verbose -Message "[$ThisModule] Configuring WinRM HTTPS server listener options"

	# Add new HTTPS listener
	New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
		-ValueSet @{ Hostname = $Domain; Enabled = $true; CertificateThumbprint = $Cert.Thumbprint } | Out-Null

	if ($Protocol -eq "HTTPS")
	{
		# Disable HTTP listener created by Microsoft.PowerShell session configuration
		Write-Verbose -Message "[$ThisModule] Disabling all HTTP listeners"
		Set-WSManInstance -ResourceURI winrm/config/listener -ValueSet @{ Enabled = $false } `
			-SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null
	}
}

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

Write-Verbose -Message "[$ThisModule] Configuring WinRM server authentication options"
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
}

if ($Protocol -eq "HTTPS")
{
	$ServerOptions["AllowUnencrypted"] = $false
}
else
{
	# MSDN: Allows the client computer to request unencrypted traffic.
	# The default value is false
	$ServerOptions["AllowUnencrypted"] = $true
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
		# HACK: Need to handle this somehow
		Write-Error -Category InvalidOperation -TargetObject $ServerOptions -ErrorAction "Continue" `
			-Message "Enabling WinRM server failed because one of the network connection types on this machine is set to 'Public'"

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
			Write-Warning -Message "To resolve this problem, uninstall Hyper-V or disable unneeded virtual switches and try again"
		}

		return
	}
	else
	{
		Write-Error -ErrorRecord $_ -EA Stop
	}
}

# Remove WinRM predefined compatibility rules
Get-NetFirewallRule -Group "@FirewallAPI.dll,-30252" -PolicyStore PersistentStore | Remove-NetFirewallRule

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

Write-Information -Tags "Project" -MessageData "INFO: WinRM server configuration was successful"

if (!$SkipTestConnection)
{
	$WSManParams = @{
		Authentication = "Default"
	}

	# NOTE: If using SSL on localhost, it would go trough network stack and for this we need authentication
	# Otherwise error is "The server certificate on the destination computer (localhost) has the
	# following errors: Encountered an internal error in the SSL library.
	if (($Domain -ne ([System.Environment]::MachineName)) -or ($Protocol -ne "HTTP"))
	{
		$WSManParams["ComputerName"] = $Domain
		# TODO: Already defined in ProjectSettings.ps1
		$WSManParams["Credential"] = Get-Credential -Message "Credentials are required to access host '$Domain'"
	}

	if ($Protocol -ne "HTTP")
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on localhost '$Domain'"
		Test-WSMan -UseSSL @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}

	if ($Protocol -ne "HTTPS")
	{
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTP on localhost '$Domain'"
		Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}
}

# Update-Log
