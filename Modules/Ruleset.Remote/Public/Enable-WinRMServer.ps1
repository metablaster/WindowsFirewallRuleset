
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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

<#
.SYNOPSIS
Configure WinRM server for CIM and PowerShell remoting

.DESCRIPTION
Configures local machine to accept local or remote CIM and PowerShell requests using WS-Management.
In addition it initializes specialized remoting session configuration as well as most common
issues are handled and attempted to be resolved automatically.

If -Protocol parameter is set to HTTPS, it will export public key (DER encoded CER file)
to default repository location (\Exports), which you should then copy to client machine
to be picked up by Set-WinRMClient and used for communication over SSL.

.PARAMETER Protocol
Specifies listener protocol to HTTP, HTTPS or Default.
The default value is "Default", which configures both HTTP and HTTPS.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default new self signed certifcate is made and trusted if no suitable certificate exists.
This must be PFX file.

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER KeepDefault
If specified, keeps default session configurations enabled.
This is needed to be able to specify -ComputerName parameter in commands that support it

.PARAMETER Loopback
If specified, only loopback server is enabled.
Remote connections to this computer will not work.

.PARAMETER Force
If specified, overwrites an existing exported certificate (*.cer) file,
unless it has the Read-only attribute set.

.EXAMPLE
PS> Enable-WinRMServer -Confirm:$false

Configures server machine to accept remote commands using SSL.
If there is no server certificate a new one self signed is made and put into trusted root.

.EXAMPLE
PS> Enable-WinRMServer -CertFile C:\Cert\Server2.pfx -Protocol Default

Configures server machine to accept remote commands using using either HTTPS or HTTP.
Client will authenticate with specified certificate for HTTPS.

.EXAMPLE
PS> Enable-WinRMServer -Protocol HTTP

Configures server machine to accept remoting commands trough HTTP.

.EXAMPLE
PS> Enable-WinRMServer -Loopback -Confirm:$false -KeepDefault

Will make WinRM work only on loopback and default session configurations stay enabled

.INPUTS
None. You cannot pipe objects to Enable-WinRMServer

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
NOTE: Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Optionally authenticate users using certificates in addition to credentials
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Configure server remotely either with WSMan or trough SSH, to test and configure server
remotely use Connect-WSMan and New-WSManSessionOption
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected
TODO: Implement specifying listening addresses and address ranges

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-WinRMServer.md

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
function Enable-WinRMServer
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default", SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-WinRMServer.md")]
	[OutputType([void], [System.Xml.XmlElement])]
	param (
		[Parameter()]
		[ValidateSet("HTTP", "HTTPS", "Default")]
		[string] $Protocol = $RemotingProtocol,

		[Parameter(ParameterSetName = "File")]
		[string] $CertFile,

		[Parameter(ParameterSetName = "Thumbprint")]
		[string] $CertThumbprint,

		[Parameter()]
		[switch] $KeepDefault,

		[Parameter()]
		[switch] $Loopback,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeServer -AllowUnencrypted:($Protocol -ne "HTTPS")
	. $PSScriptRoot\..\Scripts\SessionSettings.ps1
	$Domain = [System.Environment]::MachineName

	if ($Loopback)
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Enabling WinRM loopback server..."
	}
	else
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Enabling WinRM remoting server..."
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
	Initialize-WinRM

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Remove default session configurations"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing default session configurations"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# "PowerShell." + "current PowerShell version"
			# "PowerShell.7", untied to any specific PowerShell version.
			$DefaultSession = "PowerShell.$($PSVersionTable.PSVersion.Major)*"
		}
		else
		{
			# NOTE: "Microsoft.PowerShell" session is also used by Ruleset.Compatibility module
			# "Microsoft.PowerShell" is used for sessions by default
			# "Microsoft.PowerShell32" is used for sessions by 32bit host
			# "Microsoft.PowerShell.Workflow" is used by workflows
			$DefaultSession = "Microsoft.PowerShell*"
		}

		# Remove all default and repository specifc session configurations
		Get-PSSessionConfiguration | Where-Object {
			($_.Name -like $DefaultSession) -or
			($_.Name -eq $script:RemoteFirewallSession) -or
			($_.Name -eq $script:LocalFirewallSession)
		} | Unregister-PSSessionConfiguration -NoServiceRestart -Force
	}

	if ($script:Workstation)
	{
		# For workstations remote registry works on private profile only
		# TODO: Need to handle interface profile depending on system role (server or workstation)
		# for both Enable-WinRMServer and Set-WinRMClient
		# TODO: This check doesn't account for remote computer which might be on public network
		if ((Get-NetConnectionProfile | Select-Object -ExpandProperty NetworkCategory) -ne "Private")
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Remote deployment will not work over public network profile"
		}
	}

	Unblock-NetProfile

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Recreate default session configurations"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Recreating default session configurations"

		try
		{
			# NOTE: Enable-PSRemoting may fail in Windows PowerShell
			Set-StrictMode -Off

			# NOTE: For Register-PSSessionConfiguration to succeed Enable-PSRemoting must have been called at least once to avoid error:
			# The WinRM plugin DLL pwrshplugin.dll is missing for PowerShell.
			# Please run Enable-PSRemoting and then retry this command.
			# TODO: See if pwrshplugin.dll could be installed manually without running Enable-PSRemoting
			# Current workaround is to run Enable-PSRemoting before calling Register-PSSessionConfiguration
			# TODO: Use Set-WSManQuickConfig since recreating default session configurations is not absolutely needed
			# TODO: Since it creates HTTP listener we should probably remove all listeners before creating our own
			Enable-PSRemoting -Force | Out-Null
			Set-StrictMode -Version Latest
		}
		catch [System.OperationCanceledException]
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Operation incomplete because $($_.Exception.Message)"
		}
		catch
		{
			Write-Error -ErrorRecord $_
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Register custom session configuration"))
	{
		# Re-register repository specific session configuration
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Registering custom session configuration"

		$LocalSessionConfigParams = @{
			Name = $script:LocalFirewallSession
			Path = "$PSScriptRoot\..\Scripts\LocalFirewall.pssc"
			# If the script generates any errors, including non-terminating errors, the New-PSSession command fails.
			StartupScript = "$PSScriptRoot\..\Scripts\SessionStartupScript.ps1"
			ProcessorArchitecture = $SessionConfigParams["ProcessorArchitecture"]
			MaximumReceivedDataSizePerCommandMB = $SessionConfigParams["MaximumReceivedDataSizePerCommandMB"]
			MaximumReceivedObjectSizeMB = $SessionConfigParams["MaximumReceivedObjectSizeMB"]
			# NOTE: "Remote" is required for New-PSSession even for localhost
			AccessMode = $SessionConfigParams["AccessMode"]
			ThreadApartmentState = $SessionConfigParams["ThreadApartmentState"]
			ThreadOptions = $SessionConfigParams["ThreadOptions"]
			TransportOption = New-PSTransportOption @TransportConfigParams
			# RunAsCredential = $SessionConfigParams["RunAsCredential"]
			UseSharedProcess = $SessionConfigParams["UseSharedProcess"]
			# TODO: Does not show the UI in Remote-SSH and it's unclear if what SDDL would make Remote-SSH work
			# SecurityDescriptorSddl = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)(A;;GA;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
			# SecurityDescriptorSddl = & "$ProjectRoot\Scripts\Experiment\New-SDDL.ps1"
		}

		Set-StrictMode -Off
		Register-PSSessionConfiguration @LocalSessionConfigParams -NoServiceRestart -Force | Out-Null
		Set-StrictMode -Version Latest

		if (!$Loopback)
		{
			$RemoteSessionConfigParams = @{
				Name = $script:RemoteFirewallSession
				Path = "$PSScriptRoot\..\Scripts\RemoteFirewall.pssc"
				StartupScript = "$PSScriptRoot\..\Scripts\SessionStartupScript.ps1"
				ProcessorArchitecture = $SessionConfigParams["ProcessorArchitecture"]
				MaximumReceivedDataSizePerCommandMB = $SessionConfigParams["MaximumReceivedDataSizePerCommandMB"]
				MaximumReceivedObjectSizeMB = $SessionConfigParams["MaximumReceivedObjectSizeMB"]
				AccessMode = $SessionConfigParams["AccessMode"]
				ThreadApartmentState = $SessionConfigParams["ThreadApartmentState"]
				ThreadOptions = $SessionConfigParams["ThreadOptions"]
				TransportOption = New-PSTransportOption @TransportConfigParams
				# RunAsCredential = $SessionConfigParams["RunAsCredential"]
				UseSharedProcess = $SessionConfigParams["UseSharedProcess"]
				# SecurityDescriptorSddl = $SessionConfigParams["SecurityDescriptorSddl"]
			}

			# NOTE: Register-PSSessionConfiguration may fail in Windows PowerShell
			Set-StrictMode -Off
			# [Microsoft.WSMan.Management.WSManConfigContainerElement]
			Register-PSSessionConfiguration @RemoteSessionConfigParams -NoServiceRestart -Force | Out-Null
			Set-StrictMode -Version Latest
		} # if loopback
	}

	if (!$KeepDefault -and $PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable unneeded default session configurations"))
	{
		# Disable unused default session configurations
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling unneeded default session configurations"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Disable-PSSessionConfiguration -Name "PowerShell.$($PSVersionTable.PSVersion)" -NoServiceRestart -Force
			Disable-PSSessionConfiguration -Name "PowerShell.$($PSVersionTable.PSVersion.Major)" -NoServiceRestart -Force
		}
		else
		{
			# NOTE: "Microsoft.PowerShell" default session is used by Ruleset.Compatibility module
			Disable-PSSessionConfiguration -Name Microsoft.PowerShell32 -NoServiceRestart -Force
			Disable-PSSessionConfiguration -Name Microsoft.Powershell.Workflow -NoServiceRestart -Force
		}
	}

	# NOTE: If this plugin is disabled, PS remoting will work but CIM commands will fail
	$WmiPlugin = Get-Item WSMan:\localhost\Plugin\"WMI Provider"\Enabled
	if ($WmiPlugin.Value -eq $false)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Enable WMI Provider plugin"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Enabling WMI Provider plugin"
			Set-Item -Path WSMan:\localhost\Plugin\"WMI Provider"\Enabled -Value $true -WA Ignore
		}
	}

	# NOTE: This registry key does not affect computers that are members of an Active Directory domain.
	# In this case, Enable-PSRemoting does not create the key,
	# and you don't have to set it to 0 after disabling remoting with Disable-PSRemoting
	if (!(Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain))
	{
		# NOTE: LocalAccountTokenFilterPolicy must be enabled for New-PSSession to work
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Enable registry setting to allow remote access to Administrators"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Enable registry setting to allow remote access to Administrators"

			# Ensure registry setting was updated
			$TokenKey = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
			$TokenValue = $TokenKey.GetValue("LocalAccountTokenFilterPolicy")

			if (!$TokenValue -or ($TokenValue -ne 1))
			{
				# In some cases Enable-PSRemoting did not set it
				Write-Warning -Message "[$($MyInvocation.InvocationName)] LocalAccountTokenFilterPolicy was not enabled (value = '$TokenValue'), setting manually"

				Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 1 `
					-Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
			}
		}
	}

	if ($Loopback)
	{
		# TODO: Restore-NetProfile is needed here?
		# TODO: Protocol parameter is ignored
		if ($Protocol -ne "Default")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Protocol switch was ignored"
		}

		# NOTE: It's easier to continue with Disable-WinRMServer rather than copying
		# sections of code there, also easier to maintain because of less code duplication
		Disable-WinRMServer -KeepDefault:$KeepDefault

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Enabling WinRM loopback server completed successfully!"
		return
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server listener"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server listener"
		Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse

		# NOTE: -Force is used for "New-Item" to avoid prompting for acceptance to create listener
		if ($Protocol -ne "HTTPS")
		{
			# Add new HTTP listener
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring HTTP listener options"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				New-Item -Path WSMan:\localhost\Listener -Address * -Transport HTTP -Enabled $true -Force | Out-Null
			}
			else
			{
				New-WSManInstance -ResourceURI winrm/config/Listener -ValueSet @{ Enabled = $true } `
					-SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null
			}
		}

		if ($Protocol -ne "HTTP")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring HTTPS listener options"

			# SSL certificate
			[hashtable] $SSLCertParams = @{
				ProductType = "Server"
				Force = $Force
				PassThru = $true
			}

			if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
			elseif (![string]::IsNullOrEmpty($CertThumbprint)) { $SSLCertParams["CertThumbprint"] = $CertThumbprint }
			$Cert = Register-SslCertificate @SSLCertParams

			if ($Cert)
			{
				if ($PSVersionTable.PSEdition -eq "Core")
				{
					New-Item -Path WSMan:\localhost\Listener -Address * -Transport HTTPS -Enabled $true -Force `
						-Hostname $Domain -CertificateThumbprint $Cert.Thumbprint | Out-Null
				}
				else
				{
					# Add new HTTPS listener
					New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
						-ValueSet @{ Hostname = $Domain; Enabled = $true; CertificateThumbprint = $Cert.Thumbprint } | Out-Null
				}
			}
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server authentication options"))
	{
		# Specify acceptable client authentication methods
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server authentication options"

		# NOTE: Not assuming WinRM responds, contact localhost
		if (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain)
		{
			$AuthenticationOptions["Kerberos"] = $true
		}

		if ($Protocol -ne "HTTP")
		{
			$AuthenticationOptions["Certificate"] = $true
		}

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\service\auth\Kerberos -Value $AuthenticationOptions["Kerberos"]
			Set-Item -Path WSMan:\localhost\service\auth\Certificate -Value $AuthenticationOptions["Certificate"]
			Set-Item -Path WSMan:\localhost\service\auth\Basic -Value $AuthenticationOptions["Basic"]
			Set-Item -Path WSMan:\localhost\service\auth\CredSSP -Value $AuthenticationOptions["CredSSP"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure default server ports"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM default server ports"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTP -Value $PortOptions["HTTP"]
			Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTPS -Value $PortOptions["HTTPS"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/service/DefaultPorts -ValueSet $PortOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server options"

		if ($Protocol -eq "HTTPS")
		{
			$ServerOptions["AllowUnencrypted"] = $false
		}

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\service\MaxConcurrentOperationsPerUser -Value $ServerOptions["MaxConcurrentOperationsPerUser"]
			Set-Item -Path WSMan:\localhost\service\EnumerationTimeoutms -Value $ServerOptions["EnumerationTimeoutms"]
			Set-Item -Path WSMan:\localhost\service\MaxConnections -Value $ServerOptions["MaxConnections"]
			Set-Item -Path WSMan:\localhost\service\MaxPacketRetrievalTimeSeconds -Value $ServerOptions["MaxPacketRetrievalTimeSeconds"]
			Set-Item -Path WSMan:\localhost\service\AllowUnencrypted -Value $ServerOptions["AllowUnencrypted"]
			Set-Item -Path WSMan:\localhost\service\IPv4Filter -Value $ServerOptions["IPv4Filter"]
			Set-Item -Path WSMan:\localhost\service\IPv6Filter -Value $ServerOptions["IPv6Filter"]
			Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpListener -Value $ServerOptions["EnableCompatibilityHttpListener"]
			Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpsListener -Value $ServerOptions["EnableCompatibilityHttpsListener"]
		}
		else
		{
			# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
			# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
			Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure protocol options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM protocol options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\config\MaxEnvelopeSizekb -Value $ProtocolOptions["MaxEnvelopeSizekb"]
			Set-Item -Path WSMan:\localhost\config\MaxTimeoutms -Value $ProtocolOptions["MaxTimeoutms"]
			Set-Item -Path WSMan:\localhost\config\MaxBatchItems -Value $ProtocolOptions["MaxBatchItems"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
		}
	}

	Restore-NetProfile

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set WinRS options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRS options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# NOTE: Disable warnings which say:
			# The updated configuration might affect the operation of the plugins having a per plugin quota value greater than
			$PreviousPreference = $WarningPreference
			$WarningPreference = "SilentlyContinue"
			Set-Item -Path WSMan:\localhost\Shell\AllowRemoteShellAccess -Value $WinRSOptions["AllowRemoteShellAccess"]
			Set-Item -Path WSMan:\localhost\Shell\IdleTimeout -Value $WinRSOptions["IdleTimeout"]
			Set-Item -Path WSMan:\localhost\Shell\MaxConcurrentUsers -Value $WinRSOptions["MaxConcurrentUsers"]
			Set-Item -Path WSMan:\localhost\Shell\MaxProcessesPerShell -Value $WinRSOptions["MaxProcessesPerShell"]
			Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value $WinRSOptions["MaxMemoryPerShellMB"]
			Set-Item -Path WSMan:\localhost\Shell\MaxShellsPerUser -Value $WinRSOptions["MaxShellsPerUser"]
			$WarningPreference = $PreviousPreference
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet $WinRSOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Remove 'Windows Remote Management - Compatibility Mode' firewall rules"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing default WinRM compatibility firewall rules"

		# Remove WinRM predefined compatibility rules
		Remove-NetFirewallRule -Group $WinRMCompatibilityRules -Direction Inbound -PolicyStore PersistentStore
	}

	if ($script:Workstation)
	{
		if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Restore 'Windows Remote Management' firewall rules to default"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restoring default WinRM firewall rules"

			# Restore public profile rules to local subnet which is the default for workstations
			Get-NetFirewallRule -Group $WinRMRules -Direction Inbound -PolicyStore PersistentStore |
			Where-Object { $_.Profile -like "*Public*" } | Set-NetFirewallRule -RemoteAddress LocalSubnet
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "restart service"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restarting WS-Management (WinRM) service"

		$WinRM.Stop()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		$WinRM.Start()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Enabling WinRM remoting server completed successfully!"
}
