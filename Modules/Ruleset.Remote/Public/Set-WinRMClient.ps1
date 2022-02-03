
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
Configure client computer for WinRM remoting

.DESCRIPTION
Configures client machine to send CIM and PowerShell commands to remote server using WS-Management.
This functionality is most useful when setting up WinRM with SSL.

.PARAMETER Domain
Computer name which is to be managed remotely from this machine.
If not specified local machine is the default.

.PARAMETER Protocol
Specifies protocol to HTTP, HTTPS or any.
By default both HTTP and HTTPS is configured.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default certificate store is searched for certificate with CN entry set to value specified by
-Domain parameter.
If not found, default repository location (\Exports) is searched for DER encoded CER file.

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER TrustedHosts
Optionally append computers or IP addresses to trusted hosts.
To specify multiple hosts, separate then with comma without spaces.
This is required for HTTP

.PARAMETER Force
If specified, does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

.EXAMPLE
PS> Set-WinRMClient -Domain Server1

Configures client machine to run commands remotely on computer Server1 using SSL,
by installing Server1 certificate into trusted root.

.EXAMPLE
PS> Set-WinRMClient -Domain Server2 -CertFile C:\Cert\Server2.cer

Configures client machine to run commands remotely on computer Server2, using SSL
by installing specified certificate file into trusted root store.

.EXAMPLE
PS> Set-WinRMClient -Domain Server3 -Protocol HTTP -TrustedHosts "172.64.9.4,RemoteComputer,192.168.2.155"

Configures client machine to run commands remotely on computer Server3 using HTTP, and allows
connection to hosts specified by -TrustedHosts parameter.

.INPUTS
None. You cannot pipe objects to Set-WinRMClient

.OUTPUTS
[void]
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Authenticate users using certificates optionally or instead of credential object
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Set-WinRMClient.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

.LINK
winrm help config
#>
function Set-WinRMClient
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default", SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Set-WinRMClient.md")]
	[OutputType([void], [System.Xml.XmlElement])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[ValidateSet("HTTP", "HTTPS", "Any")]
		[string] $Protocol = "Any",

		[Parameter(ParameterSetName = "File")]
		[string] $CertFile,

		[Parameter(ParameterSetName = "CertThumbprint")]
		[string] $CertThumbprint,

		[Parameter()]
		[string] $TrustedHosts,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeClient
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Configuring WinRM client..."

	# TODO: Initialize-WinRM and Unblock-NetProfile are called multiple times since multiple functions are needed for configuration
	Initialize-WinRM

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set client authentication options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM client authentication options"

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
			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Attempt to set 'Negotiate' authentication"))
			{
				# NOTE: If this fails, registry fix must precede all other authentication edits
				Set-Item -Path WSMan:\localhost\Client\Auth\Negotiate -Value $AuthenticationOptions["Negotiate"]
			}
		}
		catch
		{
			if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Fix 'Negotiate' authentication using registry"))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Enabling 'Negotiate' authentication failed, doing trough registry"

				# TODO: WinRM service should be restarted to pick up this fix?
				Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ `
					-Name auth_negotiate -Value ([int32] ($AuthenticationOptions["Negotiate"] -eq $true))
			}
		}

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\client\auth\Kerberos -Value $AuthenticationOptions["Kerberos"]
			Set-Item -Path WSMan:\localhost\client\auth\Certificate -Value $AuthenticationOptions["Certificate"]
			Set-Item -Path WSMan:\localhost\client\auth\Basic -Value $AuthenticationOptions["Basic"]
			Set-Item -Path WSMan:\localhost\client\auth\CredSSP -Value $AuthenticationOptions["CredSSP"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/client/auth -ValueSet $AuthenticationOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set client port options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM client ports"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\client\DefaultPorts\HTTP -Value $PortOptions["HTTP"]
			Set-Item -Path WSMan:\localhost\client\DefaultPorts\HTTPS -Value $PortOptions["HTTPS"]
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/client/DefaultPorts -ValueSet $PortOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set client options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM client options"

		if (![string]::IsNullOrEmpty($TrustedHosts) -and ($Protocol -ne "HTTPS"))
		{
			if ([string]::IsNullOrEmpty($ClientOptions["TrustedHosts"]))
			{
				$ClientOptions["TrustedHosts"] = $TrustedHosts
			}
			else
			{
				$ClientOptions["TrustedHosts"] = "$($ClientOptions["TrustedHosts"]), $TrustedHosts"
			}

			Write-Debug -Message "Client options set to $($ClientOptions["TrustedHosts"])"
		}

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			Set-Item -Path WSMan:\localhost\client\NetworkDelayms -Value $ClientOptions["NetworkDelayms"]
			Set-Item -Path WSMan:\localhost\client\URLPrefix -Value $ClientOptions["URLPrefix"]
			Set-Item -Path WSMan:\localhost\client\AllowUnencrypted -Value $ClientOptions["AllowUnencrypted"]
			Set-Item -Path WSMan:\localhost\client\TrustedHosts -Value $ClientOptions["TrustedHosts"] -Concatenate -Force
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/client -ValueSet $ClientOptions | Out-Null
		}
	}

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set protocol options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM protocol options"
		Unblock-NetProfile

		try
		{
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				# TODO: protocol and WinRS options are common to client and server
				Set-Item -Path WSMan:\localhost\config\MaxEnvelopeSizekb -Value $ProtocolOptions["MaxEnvelopeSizekb"]
				Set-Item -Path WSMan:\localhost\config\MaxTimeoutms -Value $ProtocolOptions["MaxTimeoutms"]
				Set-Item -Path WSMan:\localhost\config\MaxBatchItems -Value $ProtocolOptions["MaxBatchItems"]
			}
			else
			{
				# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
				# cmd.exe /C 'winrm set winrm/config @{ MaxTimeoutms = 10 }'
				Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
			}
		}
		catch [System.OperationCanceledException]
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Operation incomplete because $($_.Exception.Message)"
		}
		catch
		{
			Write-Error -ErrorRecord $_
		}

		Restore-NetProfile

		if ($Protocol -eq "HTTPS")
		{
			# SSL certificate
			[hashtable] $SSLCertParams = @{
				ProductType = "Client"
				Domain = $Domain
			}

			if (![string]::IsNullOrEmpty($CertFile)) { $SSLCertParams["CertFile"] = $CertFile }
			elseif (![string]::IsNullOrEmpty($CertThumbprint)) { $SSLCertParams["CertThumbprint"] = $CertThumbprint }
			Register-SslCertificate @SSLCertParams
		}
	}

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

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "restart service"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restarting WS-Management (WinRM) service"

		$WinRM.Stop()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		$WinRM.Start()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
	}

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Remove 'Windows Remote Management - Compatibility Mode' firewall rules"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing default WinRM compatibility firewall rules"

		# Remove WinRM predefined compatibility rules
		Remove-NetFirewallRule -Group $WinRMCompatibilityRules -Direction Inbound `
			-PolicyStore PersistentStore
	}

	if ($script:Workstation)
	{
		if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Restore 'Windows Remote Management' firewall rules to default"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restoring default WinRM firewall rules"

			# Restore public profile rules to local subnet which is the default
			Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore | Where-Object {
				$_.Profile -like "*Public*"
			} | Set-NetFirewallRule -RemoteAddress LocalSubnet
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] WinRM client configuration completed successfully!"
}
