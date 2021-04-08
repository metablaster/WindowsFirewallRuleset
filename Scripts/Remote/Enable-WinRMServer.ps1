
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
HACK: Set-WSManInstance may fail with public profile, as a workaround try use Set-WSManQuickConfig.
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
	[Parameter(Position = 0)]
	[ValidateSet("HTTP", "HTTPS", "Any")]
	[string] $Protocol = "HTTPS",

	[Parameter(ParameterSetName = "File")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "ThumbPrint")]
	[string] $CertThumbPrint,

	[Parameter()]
	[switch] $SkipTestConnection,

	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -Server
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true
$Domain = [System.Environment]::MachineName

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

# Remove all default and repository specifc session configurations
Write-Verbose -Message "[$ThisModule] Removing default session configurations"
Get-PSSessionConfiguration | Where-Object {
	$_.Name -like "Microsoft*" -or
	$_.Name -eq "RemoteFirewall"
} | Unregister-PSSessionConfiguration -NoServiceRestart -Force

Write-Verbose -Message "[$ThisModule] Registering custom session configuration"
# NOTE: Register-PSSessionConfiguration will fail in Windows PowerShell otherwise
Set-StrictMode -Off

# [Microsoft.WSMan.Management.WSManConfigContainerElement]
Register-PSSessionConfiguration -Path $ProjectRoot\Config\RemoteFirewall.pssc `
	-Name "RemoteFirewall" -ProcessorArchitecture amd64 -ThreadApartmentState Unknown `
	-ThreadOptions UseCurrentThread -AccessMode Remote -NoServiceRestart -Force `
	-MaximumReceivedDataSizePerCommandMB 50 -MaximumReceivedObjectSizeMB 10 | Out-Null
# TODO: -RunAsCredential $RemoteCredential -UseSharedProcess `
# -SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
Set-StrictMode -Version Latest

# Register repository specific session configuration
Write-Verbose -Message "[$ThisModule] Recreating default session configurations"
Enable-PSRemoting -SkipNetworkProfileCheck -Force | Out-Null

# Enable default configuration
Write-Verbose -Message "[$ThisModule] Configuring WinRM server listener"
Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
if ($Protocol -ne "HTTPS")
{
	# Add new HTTP listener
	Write-Verbose -Message "[$ThisModule] Configuring HTTP listener options"
	New-WSManInstance -ResourceURI winrm/config/Listener -ValueSet @{ Enabled = $true } `
		-SelectorSet @{Address = "*"; Transport = "HTTP" } | Out-Null
}

if ($Protocol -ne "HTTP")
{
	Write-Verbose -Message "[$ThisModule] Configuring HTTPS listener options"

	# SSL certificate
	[hashtable] $SSLCertParams = @{
		Target = "Server"
		Force = $Force
	}

	if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
	elseif (![string]::IsNullOrEmpty($CertThumbPrint)) { $SSLCertParams["CertThumbPrint"] = $CertThumbPrint }
	$Cert = & $PSScriptRoot\Install-SslCertificate.ps1 @SSLCertParams

	# Add new HTTPS listener
	New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
		-ValueSet @{ Hostname = $Domain; Enabled = $true; CertificateThumbprint = $Cert.Thumbprint } | Out-Null
}

# Specify acceptable client authentication methods
Write-Verbose -Message "[$ThisModule] Configuring WinRM server authentication options"

# NOTE: Not assuming WinRM responds, contact localhost
if (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain)
{
	$AuthenticationOptions["Kerberos"] = $true
}

if ($Protocol -ne "HTTP")
{
	$AuthenticationOptions["Certificate"] = $true
}

# TODO: Test registry fix for cases when Negotiate is disabled
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server options"

if ($Protocol -eq "HTTPS")
{
	$ServerOptions["AllowUnencrypted"] = $false
}

try
{
	# NOTE: This will fail if any adapter is on public network
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
			-Message "Setting WinRM service options failed because one of the network connection types on this machine is set to 'Public'"

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
		Write-Error -ErrorRecord $_ -EA Stop
	}
}
catch
{
	Write-Error -ErrorRecord $_ -EA Stop
}
finally
{
	# Remove WinRM predefined compatibility rules
	Get-NetFirewallRule -Group "@FirewallAPI.dll,-30252" -PolicyStore PersistentStore | Remove-NetFirewallRule

	Write-Verbose -Message "[$ThisModule] Restarting WinRM service"
	$WinRM.Stop()
	$WinRM.WaitForStatus("Stopped", $ServiceTimeout)
	$WinRM.Start()
	$WinRM.WaitForStatus("Running", $ServiceTimeout)
}

Write-Information -Tags "Project" -MessageData "INFO: WinRM server configuration was successful"

if (!$SkipTestConnection)
{
	$WSManParams = @{
		Authentication = "Default"
	}

	# NOTE: If using SSL on localhost, it would go trough network stack and for this we need authentication
	# Otherwise error is: "The server certificate on the destination computer (localhost) has the
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

Update-Log
