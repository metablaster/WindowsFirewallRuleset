
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
In addition it initializes specialized remoting session configuration as well as most common
issues are handled and attempted to be resolved or bypassed automatically.

If specified -Protocol is set to HTTPS, it will export public key (DER encoded CER file)
to default repository location (\Exports), which you should then copy to client machine
to be picked up by Set-WinRMClient.ps1 and used for client SSL authentication.

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

.PARAMETER Force
If specified, overwrites an existing exported certificate (*.cer) file,
unless it has the Read-only attribute set.
Also it does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1

Configures server machine to accept remote commands using SSL.
If there is no server certificate a new one self signed is made and put into trusted root.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1 -CertFile C:\Cert\Server2.pfx -Protocol Any

Configures server machine to accept remote commands using using either HTTPS or HTTP.
Client will authenticate with specified certificate for HTTPS.

.EXAMPLE
PS> .\Enable-WinRMServer.ps1 -Protocol HTTP

Configures server machine to accept remoting commands trough HTTP.

.INPUTS
None. You cannot pipe objects to Enable-WinRMServer.ps1

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
NOTE: Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Authenticate users using certificates instead of or optionally in addition to credential object
TODO: Needs testing with PS Core
TODO: Risk mitigation
TODO: Check parameter naming convention
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Remote registry setup
TODO: Configure server remotely either with WSMan or trough SSH

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
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\WinRMSettings.ps1 -IncludeServer
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

# Work Station (1)
# Domain Controller (2)
# Server (3)
$Workstation = (Get-CimInstance -ClassName Win32_OperatingSystem |
	Select-Object -ExpandProperty ProductType) -eq 1

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
				Write-Error -Category OperationStopped -TargetObject $Alias `
					-Message "Setting WinRM service options was canceled"
			}
		}
	}

	[array] $VirtualAdapter = Get-NetIPConfiguration | Where-Object { !$_.NetProfile }

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
				Write-Error -Category OperationStopped -TargetObject $Alias `
					-Message "Setting WinRM service options was canceled"
			}
		}
	}
}

# NOTE: "Windows Remote Management" predefined rules (including compatibility rules) if not
# present may cause issues adjusting some of the WinRM options
if (!(Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore))
{
	Write-Verbose -Message "[$ThisModule] Adding firewall rules 'Windows Remote Management'"

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

# Re-register repository specific session configuration
Write-Verbose -Message "[$ThisModule] Registering custom session configuration"

# A null value does not affect the session configuration.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-pstransportoption
$TransportConfig = @{
	# Limits the number of sessions that use the session configuration.
	# The MaxSessions parameter corresponds to the MaxShells property of a session configuration.
	# The default value is 25.
	MaxSessions = 1

	# Determines how command output is managed in disconnected sessions when the output buffer becomes full
	# "Block", When the output buffer is full, execution is suspended until the buffer is clear
	OutputBufferingMode = "Block"
}

# [Microsoft.WSMan.Management.WSManConfigContainerElement]
$SessionConfigParams = @{
	Name = "RemoteFirewall"
	Path = "$ProjectRoot\Config\RemoteFirewall.pssc"

	# Determines whether a 32-bit or 64-bit version of the PowerShell process is started in sessions
	# x86 or amd64,
	# The default value is determined by the processor architecture of the computer that hosts the session configuration.
	ProcessorArchitecture = "amd64"

	# Maximum amount of data that can be sent to this computer in any single remote command.
	# The default is 50 MB
	MaximumReceivedDataSizePerCommandMB = 50

	# Maximum amount of data that can be sent to this computer in any single object.
	# The default is 10 MB
	MaximumReceivedObjectSizeMB = 10

	# Disabled, this configuration cannot be used for remote or local access to the computer.
	# Local, allows users of the local computer to create a loopback session on the same computer.
	# Remote, allows local and remote users to create sessions and run commands on this computer.
	AccessMode = "Remote"

	# The apartment state of the threading module to be used:
	# MTA: The Thread will create and enter a multithreaded apartment.
	# STA: The Thread will create and enter a single-threaded apartment.
	# Unknown: The ApartmentState property has not been set.
	# https://docs.microsoft.com/en-us/dotnet/api/system.threading.apartmentstate
	ThreadApartmentState = "Unknown"

	# The specified script runs in the new session that uses the session configuration.
	# If the script generates an error, even a non-terminating error, the session is not created.
	# TODO: Following path is created by "MountUserDrive" option in RemoteFirewall.pssc (another option is: ScriptsToProcess in *.pssc)
	# StartupScript = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\DriveRoots\$env:USERDOMAIN_$env:USERNAME\ProjectSettings.ps1"

	# The default value is UseCurrentThread.
	# https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.psthreadoptions
	ThreadOptions = "UseCurrentThread"

	# Advanced options for a session configuration
	TransportOption = New-PSTransportOption @TransportConfig

	# Specifies credentials for commands in the session.
	# By default, commands run with the permissions of the current user.
	# RunAsCredential = Get-Credential
}

# NOTE: Register-PSSessionConfiguration may fail in Windows PowerShell
Set-StrictMode -Off

# TODO: -RunAsCredential $RemoteCredential -UseSharedProcess -SessionTypeOption `
# -SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
Register-PSSessionConfiguration @SessionConfigParams -NoServiceRestart -Force | Out-Null
Set-StrictMode -Version Latest

Write-Verbose -Message "[$ThisModule] Recreating default session configurations"
Enable-PSRemoting -Force | Out-Null

# Disable unused built in session configurations
Write-Verbose -Message "[$ThisModule] Disabling unneeded default session configurations"
Disable-PSSessionConfiguration -Name Microsoft.PowerShell32 -NoServiceRestart -Force
Disable-PSSessionConfiguration -Name Microsoft.Powershell.Workflow -NoServiceRestart -Force

Write-Verbose -Message "[$ThisModule] Configuring WinRM server listener"
Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse

if ($Protocol -ne "HTTPS")
{
	# Add new HTTP listener
	Write-Verbose -Message "[$ThisModule] Configuring HTTP listener options"
	New-WSManInstance -ResourceURI winrm/config/Listener -ValueSet @{ Enabled = $true } `
		-SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null
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
	$Cert = & $PSScriptRoot\Register-SslCertificate.ps1 @SSLCertParams

	# Add new HTTPS listener
	New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
		-ValueSet @{ Hostname = $Domain; Enabled = $true; CertificateThumbprint = $Cert.Thumbprint } | Out-Null
}

# NOTE: If this plugin is disabled, PS remoting will work but CIM commands will fail
$WmiPlugin = Get-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled
if ($WmiPlugin.Value -ne $true)
{
	Write-Information -Tags "Project" -MessageData "INFO: Enabling WMI Provider plugin"
	Set-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled -Value $true -WA Ignore
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

# TODO: Test registry fix for cases when Negotiate is disabled (see Set-WinRMClient.ps1)
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM default server ports"
Set-WSManInstance -ResourceURI winrm/config/service/DefaultPorts -ValueSet $PortOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM server options"

if ($Protocol -eq "HTTPS")
{
	$ServerOptions["AllowUnencrypted"] = $false
}

# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null

Write-Verbose -Message "[$ThisModule] Configuring WinRM protocol options"
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

# Remove WinRM predefined compatibility rules
Remove-NetFirewallRule -Group $WinRMCompatibilityRules -Direction Inbound `
	-PolicyStore PersistentStore

# Restore public profile rules to local subnet which is the default
Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore | Where-Object {
	$_.Profile -like "*Public*"
} | Set-NetFirewallRule -RemoteAddress LocalSubnet

Write-Verbose -Message "[$ThisModule] Restarting WinRM service"
$WinRM.Stop()
$WinRM.WaitForStatus("Stopped", $ServiceTimeout)
$WinRM.Start()
$WinRM.WaitForStatus("Running", $ServiceTimeout)

$TokenKey = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$TokenValue = $TokenKey.GetValue("LocalAccountTokenFilterPolicy")

if ($TokenValue -ne 1)
{
	Write-Error -Category InvalidResult -TargetObject $TokenValue `
		-Message "LocalAccountTokenFilterPolicy was not enabled"
}

Write-Information -Tags "Project" -MessageData "INFO: WinRM server configuration was successful"
Update-Log
