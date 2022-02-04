
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
PowerShell remoting, remoting with CIM commandlets and user authentication.

.PARAMETER Domain
Target host which is to be tested.
If not specified, local machine is the default

.PARAMETER Credential
Specify credentials which to use to test connection to remote computer.
If not specified, you'll be asked for credentials

.PARAMETER Protocol
Specify protocol to use for test, HTTP, HTTPS or both.
By default both HTTPS and HTTPS are tested.

.PARAMETER Port
Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port

.PARAMETER Authentication
Specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER UICulture
Specifies the user interface culture to use for the CIM session,
in Windows this setting is known as "Windows display language"
The default value is en-US, current value can be obtained with Get-UICulture

.PARAMETER Culture
Controls the formats used to represent numbers, currency values, and date/time values,
in Windows this setting is known as "Region and regional format"
The default value is en-US, current value can be obtained with Get-Culture

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
TODO: Remote registry test
TODO: Default test should be to localhost which must not ask for credentials
TODO: Test for private profile to avoid cryptic error message
#>
function Test-WinRM
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md")]
	[OutputType([void], [System.Xml.XmlElement])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
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
		[ref] $Status,

		[Parameter()]
		[switch] $Quiet
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$StatusHTTP = $false
	$StatusHTTPS = $false

	if ($Quiet)
	{
		$ErrorActionPreference = "SilentlyContinue"
		$InformationPreference = "SilentlyContinue"
	}

	if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Status"))
	{
		$Status.Value = $false
	}

	$PSSessionOption = New-PSSessionOption -UICulture $UICulture -Culture $Culture `
		-OpenTimeout 3000 -CancelTimeout 5000 -OperationTimeout 10000 -MaxConnectionRetryCount 2

	$WSManParams = @{
		Port = $Port
		Authentication = $Authentication
		ApplicationName = "wsman"
		# NOTE: Only valid for Enter-PSSession
		# SessionOption = $PSSessionOption
	}

	$CimParams = @{
		Name = "TestCim"
		Authentication = $Authentication
		Port = $WSManParams["Port"]
		OperationTimeoutSec = $PSSessionOption.OperationTimeout.TotalSeconds
		# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
		# verification is accomplished using a standard WS-Identity operation.
	}

	if (($Domain -ne ([System.Environment]::MachineName)) -and ($Domain -ne "localhost"))
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
		$WSManParams["Credential"] = $Credential

		$CimParams["ComputerName"] = $Domain
		$CimParams["Credential"] = $Credential
	}

	if ($Protocol -ne "HTTP")
	{
		$CimOptions = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture $UICulture -Culture $Culture
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimOptions $($CimOptions | Out-String)"

		$WSManParams["UseSsl"] = $true
		$CimParams["SessionOption"] = $CimOptions

		if ($CertThumbprint)
		{
			$WSManParams["CertificateThumbprint"] = $CertThumbprint
			$CimParams["CertificateThumbprint"] = $CertThumbprint
		}

		if (!$Port)
		{
			$WSManParams["Port"] = 5986
			$CimParams["Port"] = $WSManParams["Port"]
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTPS on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] WSManParams $($WSManParams | Out-String)"

		$WSManResult = Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
		if (!$Quiet) { $WSManResult }

		if (Get-CimSession -Name $CimParams["Name"] -ErrorAction Ignore)
		{
			Remove-CimSession -Name $CimParams["Name"]
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server over HTTPS on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimParams $($CimParams | Out-String)"

		$CimResult = $null
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new CIM session to '$Domain'"
		$CimServer = New-CimSession @CimParams

		if ($CimServer)
		{
			# MSDN: Get-CimInstance, if the InputObject parameter is not specified then:
			# Works against the CIM server specified by either the ComputerName or the CimSession parameter
			Write-Debug -Message "[$($MyInvocation.InvocationName)] CimServer $($CimServer | Out-String)"

			$CimResult = Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
			Select-Object CSName, Caption | Format-Table

			if (!$Quiet) { $CimResult }
			Remove-CimSession -Name $CimParams["Name"]
		}

		$StatusHTTPS = ($null -ne $WSManResult) -and ($null -ne $CimResult)
		if ($Protocol -ne "Any")
		{
			if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Status"))
			{
				$Status.Value = $StatusHTTPS
				Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM HTTPS test result is '$StatusHTTPS'"
			}
		}
	}

	if ($Protocol -ne "HTTPS")
	{
		$CimOptions = New-CimSessionOption -Protocol Wsman -UICulture $UICulture -Culture $Culture
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimOptions $($CimOptions | Out-String)"

		$WSManParams["UseSsl"] = $false
		$CimParams["SessionOption"] = $CimOptions

		if ($CertThumbprint)
		{
			$WSManParams.Remove("CertificateThumbprint")
			$CimParams.Remove("CertificateThumbprint")
		}

		if (!$Port)
		{
			$WSManParams["Port"] = 5985
			$CimParams["Port"] = $WSManParams["Port"]
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTP on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] WSManParams $($WSManParams | Out-String)"

		$WSManResult2 = Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
		if (!$Quiet) { $WSManResult2 }

		if (Get-CimSession -Name $CimParams["Name"] -ErrorAction Ignore)
		{
			Remove-CimSession -Name $CimParams["Name"]
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server over HTTP on '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimParams $($CimParams | Out-String)"

		$CimResult2 = $null
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new CIM session to '$Domain'"
		$CimServer = New-CimSession @CimParams

		if ($CimServer)
		{
			# MSDN: Get-CimInstance, if the InputObject parameter is not specified then:
			# Works against the CIM server specified by either the ComputerName or the CimSession parameter
			Write-Debug -Message "[$($MyInvocation.InvocationName)] CimServer $($CimServer | Out-String)"

			$CimResult2 = Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
			Select-Object CSName, Caption | Format-Table

			if (!$Quiet) { $CimResult2 }
			Remove-CimSession -Name $CimParams["Name"]
		}

		$StatusHTTP = ($null -ne $WSManResult2) -and ($null -ne $CimResult2)
		if ($Protocol -ne "Any")
		{
			if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Status"))
			{
				$Status.Value = $StatusHTTP
				Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM HTTP test result is '$StatusHTTP'"
			}
		}
	}

	if ($Protocol -eq "Any")
	{
		if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Status"))
		{
			$Status.Value = $StatusHTTP -or $StatusHTTPS
		}
	}
}
