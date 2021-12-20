
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

<#
.SYNOPSIS
Connect to remote computer

.DESCRIPTION
Connect to remote computer onto which to deploy firewall.
This script will perform necessary initialization to enter PS session to remote computer,
in addition required authentication is made to use remote registry service and to run commands
against remote CIM server.

Following global variables are created:
RemoteCredential, to be used by commands that require credentials.
CimServer, to be used by CIM commandlets to specify cim session to use.
RemoteRegistry, administrative share C$ to remote computer (needed for authentication)

.PARAMETER Domain
Computer name with to which to connect for remoting

.PARAMETER Protocol
Specify protocol to use for test, HTTP, HTTPS or both.
The default value is "Any" which means HTTPS is used for connection to remote computer
and HTTP for local machine.

.PARAMETER Port
Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER SessionOption
Specify custom PSSessionOption object to use for remoting.
The default value is controlled with PSSessionOption preference variable

.PARAMETER ConfigurationName
Specify session configuration to use for remoting, this session configuration must
be registered and enabled on remote computer.
The default value is controlled with PSSessionConfigurationName preference variable

.PARAMETER ApplicationName
Specify application name use for remote connection,
Currently only "wsman" is supported.
The default value is controlled with PSSessionApplicationName preference variable

.PARAMETER CimOptions
Specify custom CIM session object to fine tune CIM sessions.
By default new blank CIM options object is made and set to use SSL if protocol is HTTPS

.EXAMPLE
PS> Connect-Computer COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Connect-Computer

.OUTPUTS
None. Connect-Computer does not generate any output

.NOTES
TODO: When localhost is specified it should be treated as localhost which means localhost
requirements must be met.
#>
function Connect-Computer
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Connect-Computer.md")]
	[OutputType([void])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[ValidateSet("HTTP", "HTTPS", "Any")]
		[string] $Protocol = "Any",

		[Parameter()]
		[ValidateRange(1, 65535)]
		[int32] $Port,

		[Parameter(ParameterSetName = "ThumbPrint")]
		[string] $CertThumbprint,

		[Parameter()]
		[System.Management.Automation.Remoting.PSSessionOption]
		$SessionOption = $PSSessionOption,

		[Parameter()]
		[string] $ConfigurationName = $PSSessionConfigurationName,

		[Parameter()]
		[string] $ApplicationName = $PSSessionApplicationName,

		[Parameter()]
		[Microsoft.Management.Infrastructure.Options.CimSessionOptions]
		$CimOptions
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSSessionConfigurationName -ne $script:FirewallSession)
	{
		Write-Warning -Message "Unexpected session configuration $PSSessionConfigurationName"
	}

	# WinRM service must be running at this point
	# TODO: does not belong here, move to requirements section
	if ($WinRM.Status -ne [ServiceControllerStatus]::Running)
	{
		Write-Information -Tags $SettingsScript -MessageData "INFO: Starting WS-Management service"

		# NOTE: Unable to start if it's disabled
		if ($WinRM.StartType -eq [ServiceStartMode]::Disabled)
		{
			Set-Service -InputObject $WinRM -StartupType Manual
		}

		$WinRM.Start()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
	}

	$WSManParams = @{
		Port = $Port
		Authentication = "Default"
		ApplicationName = $ApplicationName
		SessionOption = $SessionOption
	}

	if ($CertThumbprint)
	{
		$WSManParams["CertificateThumbprint"] = $CertThumbprint
	}

	if ($Protocol -eq "Any")
	{
		$WSManParams["UseSSL"] = $Domain -ne ([System.Environment]::MachineName)
	}
	else
	{
		$WSManParams["UseSSL"] = $Protocol -eq "HTTPS"
	}

	if ($WSManParams["UseSSL"])
	{
		if (!$Port)
		{
			$WSManParams["Port"] = 5986
		}

		if (!$CimOptions)
		{
			# TODO: LocalStores needs a better place for adjustment
			$CimOptions = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture en-US -Culture en-US
		}
	}
	else
	{
		if (!$Port)
		{
			$WSManParams["Port"] = 5985
		}

		if (!$CimOptions)
		{
			$CimOptions = New-CimSessionOption -Protocol Wsman -UICulture en-US -Culture en-US
		}
	}

	$CimParams = @{
		Name = "RemoteCim"
		Authentication = "Default"
		Port = $WSManParams["Port"]
		SessionOption = $CimOptions
		OperationTimeoutSec = $SessionOption.OperationTimeout.TotalSeconds
	}

	if ($CertThumbprint)
	{
		$CimParams["CertificateThumbprint"] = $CertThumbprint
	}

	# Remote computer or localhost over SSL
	if (($Domain -ne ([System.Environment]::MachineName)) -or ($WSManParams["UseSSL"]))
	{
		if (!(Get-Variable -Name RemoteCredential -Scope Global -ErrorAction Ignore))
		{
			# TODO: -Credential param, specify SERVER\UserName
			New-Variable -Name RemoteCredential -Scope Global -Option ReadOnly (
				Get-Credential -Message "Credentials are required to access '$Domain'")

			if (!$RemoteCredential)
			{
				# Will happen if credential request was dismissed using ESC key.
				Write-Error -Category InvalidOperation -Message "Credentials are required for remote session on '$Domain'"
			}
			elseif ($RemoteCredential.Password.Length -eq 0)
			{
				# HACK: Will ask for password but won't be recorded
				Write-Error -Category InvalidData -Message "User '$($RemoteCredential.UserName)' must have a password"
				Remove-Variable -Name RemoteCredential -Scope Global -Force
			}
		}

		$CimParams["ComputerName"] = $Domain
		$CimParams["Credential"] = $RemoteCredential

		$WSManParams["ComputerName"] = $Domain
		$WSManParams["Credential"] = $RemoteCredential
	}

	try
	{
		# MSDN: A CIM session is a client-side object representing a connection to a local computer or a remote computer.
		if (!(Get-CimSession -Name RemoteCim -ErrorAction Ignore))
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Creating new CIM session to $Domain"

			# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
			# verification is accomplished using a standard WS-Identity operation.
			# NOTE: Specifying computer name may fail if WinRM listens on loopback only
			Set-Variable -Name CimServer -Scope Global -Option ReadOnly -Force -Value (New-CimSession @CimParams)
		}
	}
	catch
	{
		Remove-Variable -Name RemoteCredential -Scope Global -Force -ErrorAction Ignore
		Write-Error -Category ConnectionError -TargetObject $Domain `
			-Message "Creating CIM session to '$Domain' failed with: $($_.Exception.Message)"
	}

	if ($Domain -ne ([System.Environment]::MachineName))
	{
		try
		{
			if (!(Get-PSDrive -Name RemoteRegistry -Scope Global -ErrorAction Ignore))
			{
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Authenticating '$($RemoteCredential.UserName)' to computer '$Domain'"

				# Authentication is required to access remote registry
				# NOTE: Registry provider does not support credentials
				# TODO: More limited drive would be better
				New-PSDrive -Credential $RemoteCredential -PSProvider FileSystem -Scope Global -Name RemoteRegistry `
					-Root \\$Domain\C$ -Description "Remote registry authentication" | Out-Null
			}
		}
		catch
		{
			Remove-CimSession -Name RemoteCim
			Remove-Variable -Name CimServer -Scope Global -Force
			Remove-Variable -Name RemoteCredential -Scope Global -Force

			Write-Error -Category AuthenticationError -TargetObject $RemoteCredential `
				-Message "Authenticating $($RemoteCredential.UserName) to '$Domain' failed with: $($_.Exception.Message)"
		}

		try
		{
			# TODO: For VM without external switch use -VMName
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Entering remote session to computer '$Domain'"
			Enter-PSSession @WSManParams
		}
		catch
		{
			Remove-CimSession -Name RemoteCim
			Remove-Variable -Name CimServer -Scope Global -Force

			Remove-PSDrive -Name RemoteRegistry -Scope Global
			Remove-Variable -Name RemoteCredential -Scope Global -Force

			Write-Error -Category ConnectionError -TargetObject $Domain `
				-Message "Entering remote session to computer '$Domain' failed with: $($_.Exception.Message)"
		}
	}
}
