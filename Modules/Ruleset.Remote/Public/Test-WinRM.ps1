
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
Test WinRM service configuration

.DESCRIPTION
Test WinRM service (server) configuration on either client or server computer.
WinRM service is tested for functioning connectivity which includes
PowerShell remoting, remoting with CIM commandlets and creation of PS session.

.PARAMETER Domain
Computer name which is to be tested for functioning WinRM.
If not specified, local machine is the default

.PARAMETER Credential
Specify credentials which to use to test connection to remote computer.
Credentials are required for HTTPS and remote connections.
If not specified, you'll be asked for credentials

.PARAMETER Protocol
Specify protocol to use for test, HTTP, HTTPS or Any.
The default value is Any, which means HTTPS is tested first and if failed HTTP is tested.

.PARAMETER Port
Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port.
The default value if 5985 for HTTP and 5986 for HTTPS.

.PARAMETER Authentication
Optionally specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.
The default value is "Default"

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for HTTPS.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER UICulture
Specifies the user interface culture to use for the CIM session,
in Windows this setting is known as "Windows display language"
The default value is en-US, current value can be obtained with Get-UICulture

.PARAMETER Culture
Controls the formats used to represent numbers, currency values, and date/time values,
in Windows this setting is known as "Region and regional format"
The default value is en-US, current value can be obtained with Get-Culture

.PARAMETER ApplicationName
Specifies the application name in the connection.
The default value is controlled with PSSessionApplicationName preference variable

.PARAMETER SessionOption
Specify custom PSSessionOption object to use for remoting.
The default value is controlled with PSSessionOption variable from caller scope

.PARAMETER ConfigurationName
Specify session configuration to use for remoting, this session configuration must
be registered and enabled on remote computer.
The default value is controlled with PSSessionConfigurationName preference variable

.PARAMETER CimOptions
Optionally specify custom CIM session options to fine tune CIM session test.
By default new CIM options object is made and set to use SSL if protocol is HTTPS

.PARAMETER Status
Boolean reference variable used for return value which indicates whether the test was success

.PARAMETER Quiet
If specified, does not produce errors, success messages or informational action messages

.EXAMPLE
PS> Test-WinRM HTTP

.EXAMPLE
PS> Test-WinRM -Domain Server1 -Protocol Any

.EXAMPLE
PS> $RemoteStatus = $false
PS> Test-WinRM HTTP -Quiet -Status $RemoteStatus

.INPUTS
None. You cannot pipe objects to Test-WinRM

.OUTPUTS
None. Test-WinRM does not generate any output

.NOTES
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Test for private profile to avoid cryptic error message

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.authenticationmechanism
#>
function Test-WinRM
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Protocol",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md")]
	[OutputType([void], [System.Xml.XmlElement], [System.String], [System.URI], [System.Management.Automation.Runspaces.PSSession])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Protocol")]
		[ValidateSet("HTTP", "HTTPS", "Any")]
		[string] $Protocol = "Any",

		[Parameter()]
		[ValidateRange(1, 65535)]
		[int32] $Port,

		[ValidateSet("None", "Basic", "CredSSP", "Default", "Digest", "Kerberos", "Negotiate", "Certificate")]
		[string] $Authentication = "Default",

		[Parameter(ParameterSetName = "ThumbPrint")]
		[string] $CertThumbprint,

		[Parameter()]
		[System.Globalization.CultureInfo] $UICulture = $DefaultUICulture,

		[Parameter()]
		[System.Globalization.CultureInfo] $Culture = $DefaultCulture,

		[Parameter()]
		[string] $ApplicationName = $PSSessionApplicationName,

		[Parameter()]
		[System.Management.Automation.Remoting.PSSessionOption]
		$SessionOption = $PSSessionOption,

		[Parameter()]
		[string] $ConfigurationName = $PSSessionConfigurationName,

		[Parameter()]
		[Microsoft.Management.Infrastructure.Options.CimSessionOptions]
		$CimOptions,

		[Parameter()]
		[ref] $Status,

		[Parameter()]
		[switch] $Quiet
	)

	# $DebugPreference = "Continue"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Replace localhost and dot with NETBIOS computer name
	if (($Domain -eq "localhost") -or ($Domain -eq "."))
	{
		$Domain = [System.Environment]::MachineName
	}

	# HTTP\S connectivity status
	$StatusHTTP = $false
	$StatusHTTPS = $false

	if ($Quiet)
	{
		$ErrorActionPreference = "SilentlyContinue"
		$WarningPreference = "SilentlyContinue"
		$InformationPreference = "SilentlyContinue"
	}

	# Reset caller supplied status to false
	if ($PSBoundParameters.ContainsKey("Status"))
	{
		$Status.Value = $false
	}

	# Parameters for Test-WSMan
	$WSManParams = @{
		Port = $Port
		Authentication = $Authentication
		ApplicationName = $ApplicationName
	}

	# Parameters for CIM session object
	$CimParams = @{
		Name = "TestCim"
		Port = $Port
		SessionOption = $CimOptions
		Authentication = $Authentication
		OperationTimeoutSec = $SessionOption.OperationTimeout.TotalSeconds
		# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
		# verification is accomplished using a standard WS-Identity operation.
		# TODO: -SkipTestConnection could be used for Test-Credential function
	}

	$ConfigurationEnabled = Get-PSSessionConfiguration -Name $ConfigurationName -ErrorAction SilentlyContinue |
	Select-Object -ExpandProperty Enabled

	# If specified session is disabled or missing New-PSSession will not work
	if ($null -eq $ConfigurationEnabled)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified session configuration '$ConfigurationName' is missing"
	}
	elseif ($ConfigurationEnabled -eq $false)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified session configuration '$ConfigurationName' is disabled"
	}
	else
	{
		if (($Domain -eq [System.Environment]::MachineName) -and ($ConfigurationName -ne $script:LocalFirewallSession))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Unexpected session configuration $ConfigurationName"
		}
		elseif (($Domain -ne [System.Environment]::MachineName) -and ($ConfigurationName -ne $script:RemoteFirewallSession))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Unexpected session configuration $ConfigurationName"
		}
	}

	# Parameters for PS Session
	$PSSessionParams = @{
		# PS session name
		Name = "TestSession"
		Port = $Port
		Authentication = $Authentication
		ApplicationName = $ApplicationName
		SessionOption = $SessionOption
		# MSDN: If you specify only the configuration name, the following schema URI is prepended: http://schemas.microsoft.com/PowerShell
		ConfigurationName = $ConfigurationName
	}

	if ($Domain -ne [System.Environment]::MachineName)
	{
		# NOTE: If using SSL on localhost, it would go trough network stack for which we need
		# authentication otherwise the error is:
		# "The server certificate on the destination computer (localhost) has the following errors:
		# Encountered an internal error in the SSL library"
		if (!$Credential)
		{
			$Credential = Get-Credential -Message "Credentials are required to access '$Domain'"

			if (!$Credential)
			{
				# Will happen if credential request was dismissed using ESC key.
				Write-Error -Category InvalidOperation -Message "Credentials are required to access '$Domain'"
			}
			elseif ($Credential.Password.Length -eq 0)
			{
				# Will happen when no password is specified
				Write-Error -Category InvalidData -Message "User '$($Credential.UserName)' must have a password"
				$Credential = $null
			}
		}

		$WSManParams["ComputerName"] = $Domain
		$CimParams["ComputerName"] = $Domain
		$PSSessionParams["ComputerName"] = $Domain

		$WSManParams["Credential"] = $Credential
		$CimParams["Credential"] = $Credential
		$PSSessionParams["Credential"] = $Credential
	}

	# Test HTTPS connectivity
	if ($Protocol -ne "HTTP")
	{
		if (!$CimOptions)
		{
			$CimParams["SessionOption"] = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture $UICulture -Culture $Culture
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM options: $($CimParams["SessionOption"] | Out-String)"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] PS session options: $($SessionOption | Out-String)"

		$WSManParams["UseSsl"] = $true
		$PSSessionParams["UseSSL"] = $true

		if (![string]::IsNullOrEmpty($CertThumbprint))
		{
			$WSManParams["CertificateThumbprint"] = $CertThumbprint
			$CimParams["CertificateThumbprint"] = $CertThumbprint
			$PSSessionParams["CertificateThumbprint"] = $CertThumbprint
		}

		if (!$Port)
		{
			$WSManParams["Port"] = 5986
			$CimParams["Port"] = 5986
			$PSSessionParams["Port"] = 5986
		}

		# Test WSMan connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTPS on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] WSManParams: $($WSManParams | Out-String)"

		$WSManResult = Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
		if (!$Quiet) { $WSManResult }

		# Test CIM connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server over HTTPS on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimParams: $($CimParams | Out-String)"

		$CimResult = $null
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new CIM session to '$Domain'"
		$CimServer = New-CimSession @CimParams

		if ($CimServer)
		{
			# MSDN: Get-CimInstance, if the InputObject parameter is not specified then:
			# Works against the CIM server specified by either the ComputerName or the CimSession parameter
			Write-Debug -Message "[$($MyInvocation.InvocationName)] CimServer: $($CimServer | Out-String)"

			$CimResult = Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
			Select-Object CSName, Caption | Format-Table

			if (!$Quiet) { $CimResult }
			Remove-CimSession -Name $CimParams["Name"]
		}

		# Test PS Session connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing PS session over HTTPS on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] PSSessionParams: $($PSSessionParams | Out-String)"

		# [System.String], [System.URI] or [System.Management.Automation.Runspaces.PSSession]
		$PSSessionResult = New-PSSession @PSSessionParams
		if (!$Quiet) { $PSSessionResult }
		Remove-PSSession -Name TestSession

		if ($PSBoundParameters.ContainsKey("Status") -and ($Protocol -ne "Any"))
		{
			$StatusHTTPS = ($null -ne $WSManResult) -and ($null -ne $CimResult) -and ($null -ne $PSSessionResult)
			$Status.Value = $StatusHTTPS
			Write-Debug -Message "[$($MyInvocation.InvocationName)] HTTPS test result is '$StatusHTTPS'"
		}
	}

	# Test HTTP connectivity
	if ($Protocol -ne "HTTPS")
	{
		if (!$CimOptions)
		{
			$CimParams["SessionOption"] = New-CimSessionOption -Protocol Wsman -UICulture $UICulture -Culture $Culture
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM options: $($CimParams["SessionOption"] | Out-String)"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] PS session options: $($SessionOption | Out-String)"

		$WSManParams["UseSsl"] = $false
		$PSSessionParams["UseSSL"] = $false

		if (![string]::IsNullOrEmpty($CertThumbprint))
		{
			$WSManParams.Remove("CertificateThumbprint")
			$CimParams.Remove("CertificateThumbprint")
			$PSSessionParams.Remove("CertificateThumbprint")
		}

		if (!$Port)
		{
			$WSManParams["Port"] = 5985
			$CimParams["Port"] = 5985
			$PSSessionParams["Port"] = 5985
		}

		# Test WSMan connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTP on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] WSManParams: $($WSManParams | Out-String)"

		$WSManResult2 = Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
		if (!$Quiet) { $WSManResult2 }

		# Test CIM connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server over HTTP on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimParams: $($CimParams | Out-String)"

		$CimResult2 = $null
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new CIM session to '$Domain'"
		$CimServer = New-CimSession @CimParams

		if ($CimServer)
		{
			# MSDN: Get-CimInstance, if the InputObject parameter is not specified then:
			# Works against the CIM server specified by either the ComputerName or the CimSession parameter
			Write-Debug -Message "[$($MyInvocation.InvocationName)] CimServer: $($CimServer | Out-String)"

			$CimResult2 = Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
			Select-Object CSName, Caption | Format-Table

			if (!$Quiet) { $CimResult2 }
			Remove-CimSession -Name $CimParams["Name"]
		}

		# Test PS Session connectivity
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing PS session over HTTP on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] PSSessionParams: $($PSSessionParams | Out-String)"

		# [System.String], [System.URI] or [System.Management.Automation.Runspaces.PSSession]
		$PSSessionResult = New-PSSession @PSSessionParams
		if (!$Quiet) { $PSSessionResult }
		Remove-PSSession -Name TestSession

		if ($PSBoundParameters.ContainsKey("Status") -and ($Protocol -ne "Any"))
		{
			$StatusHTTP = ($null -ne $WSManResult2) -and ($null -ne $CimResult2) -and ($null -ne $PSSessionResult)
			$Status.Value = $StatusHTTP
			Write-Debug -Message "[$($MyInvocation.InvocationName)] HTTP test result is '$StatusHTTP'"
		}
	}

	if ($PSBoundParameters.ContainsKey("Status") -and ($Protocol -eq "Any"))
	{
		$Status.Value = $StatusHTTP -or $StatusHTTPS
	}
}
