
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

.GUID b696f7b7-ad8e-4736-b583-94e7382b5e9b

.AUTHOR metablaster zebal@protonmail.com
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

.PARAMETER Domain
Computer name with to which to connect for remoting

.PARAMETER SessionOption
Specify custom PSSessionOption object to use for remoting.
By default this is PSSessionOption preference variable

.PARAMETER ConfigurationName
Specify session configuration to use for remoting, this session configuration must
be registered and enabled on remote computer.
By default this is PSSessionConfigurationName preference variable

.PARAMETER CimOptions
Specify custom CIM session object to fine tune CIM sessions.
By default new blank CIM options object is made and set to use SSL

.EXAMPLE
PS> .\Connect-Computer.ps1 COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Connect-Computer.ps1

.OUTPUTS
None. Connect-Computer.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false)]
[OutputType([void])]
param (
	[Parameter(Position = 0)]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[System.Management.Automation.Remoting.PSSessionOption]
	$SessionOption = $PSSessionOption,

	[Parameter()]
	[string] $ConfigurationName = $PSSessionConfigurationName,

	[Parameter()]
	[Microsoft.Management.Infrastructure.Options.CimSessionOptions]
	$CimOptions = (New-CimSessionOption -UseSsl)
)

Set-Variable -Name ThisScript -Scope Private -Option ReadOnly -Force -Value ($PSCmdlet.MyInvocation.MyCommand -replace "\.\w{2,3}1$")
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

$OldSettingsScriptEA = $ErrorActionPreference
$ErrorActionPreference = "Stop"

if ($MyInvocation.InvocationName -eq '.')
{
	Write-Error -Category NotEnabled -TargetObject $MyInvocation.InvocationName `
		-Message "This script must be called, not dot sourced"
}

$WSManParams = @{
	UseSSL = $Domain -ne ([System.Environment]::MachineName)
	Authentication = "Default"
	# ApplicationName = $PSSessionApplicationName
}

$CimParams = @{
	Name = "RemoteCim"
	SessionOption = $CimOptions
	# Authentication = "Default"
	OperationTimeoutSec = $PSSessionOption.OperationTimeout.TotalSeconds
}

if ($Domain -eq ([System.Environment]::MachineName))# -or ($Domain -eq "localhost"))
{
	# NOTE: If localhost does not accept HTTP (ex. HTTPS configured WinRM server), then change this to true
	$CimOptions.UseSsl = $false
	$CimParams["SessionOption"] = $CimOptions
	# $Domain = $Domain #"localhost"
}
else # Remote computer
{
	if (!(Get-Variable -Name RemoteCredential -Scope Global -ErrorAction Ignore))
	{
		# TODO: -Credential param, specify SERVER\UserName
		New-Variable -Name RemoteCredential -Scope Global -Option Constant (
			Get-Credential -Message "Administrative credentials are required to access '$Domain'")

		if (!$RemoteCredential)
		{
			# Will happen if credential request was dismissed using ESC key.
			Write-Error -Category InvalidOperation -Message "Credentials are required for remote session on '$Domain'"
		}
		elseif ($RemoteCredential.Password.Length -eq 0)
		{
			# HACK: Will ask for password but won't be recorded
			Write-Error -Category InvalidData -Message "User '$($RemoteCredential.UserName)' must have a password"
			Remove-Variable -Name Credential -Scope Global -Force
		}
	}

	$CimParams["ComputerName"] = $Domain
	$CimParams["Credential"] = $RemoteCredential

	$WSManParams["ComputerName"] = $Domain
	$WSManParams["Credential"] = $RemoteCredential
}

try
{
	Write-Information -Tags "Project" -MessageData "INFO: Checking Windows remote management service on computer '$Domain'"
	Test-WSMan @WSManParams | Out-Null
}
catch
{
	Write-Error -Category ConnectionError -TargetObject $Domain `
		-Message "Remote management test to computer '$Domain' failed with: $($_.Exception.Message)"
}

try
{
	# MSDN: A CIM session is a client-side object representing a connection to a local computer or a remote computer.
	if (!(Get-CimSession -Name RemoteCim -ErrorAction Ignore))
	{
		Write-Verbose -Message "[$ThisScript] Creating new CIM session to $Domain"

		# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
		# verification is accomplished using a standard WS-Identity operation.
		# NOTE: Specifying computer name may fail if WinRM listens on loopback only
		Set-Variable -Name CimServer -Scope Global -Option ReadOnly -Force -Value (New-CimSession @CimParams)
	}
}
catch
{
	Write-Error -Category ConnectionError -TargetObject $Domain `
		-Message "Creating CIM session to '$Domain' failed with: $($_.Exception.Message)"
}

if ($Domain -ne ([System.Environment]::MachineName))#"localhost")
{
	try
	{
		if (!(Get-PSDrive -Name RemoteRegistry -Scope Global -ErrorAction Ignore))
		{
			Write-Information -Tags "Project" -MessageData "INFO: Authenticating '$($RemoteCredential.UserName)' to computer '$Domain'"

			# Authentication is required to access remote registry
			# NOTE: Registry provider does not support credentials
			New-PSDrive -Credential $RemoteCredential -PSProvider FileSystem -Scope Global -Name RemoteRegistry `
				-Root \\$Domain\C$ -Description "Remote registry authentication" | Out-Null
		}
	}
	catch
	{
		Write-Error -Category AuthenticationError -TargetObject $RemoteCredential `
			-Message "Authenticating $($RemoteCredential.UserName) to '$Domain' failed with: $($_.Exception.Message)"
	}

	try
	{
		# TODO: For VM without external switch use -VMName
		Write-Information -Tags "Project" -MessageData "INFO: Entering remote session to computer '$Domain'"
		Enter-PSSession @WSManParams # -UseSSL -ComputerName $Domain -Credential $RemoteCredential -ConfigurationName $PSSessionConfigurationName
	}
	catch
	{
		Write-Error -Category ConnectionError -TargetObject $Domain `
			-Message "Entering remote session to computer '$Domain' failed with: $($_.Exception.Message)"
	}
}

$ErrorActionPreference = $OldSettingsScriptEA
Remove-Variable -Name OldSettingsScriptEA
