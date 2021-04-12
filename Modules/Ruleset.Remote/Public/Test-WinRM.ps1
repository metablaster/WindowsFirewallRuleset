
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
Test WinRM service configuration

.DESCRIPTION
Test WinRM service configuration on either client or server computer.
WinRM service is tested for functioning connectivity which includes
PowerShell remoting and remoting with CIM commandlets.

.PARAMETER Domain
Target host which is to be tested.
If not specified, local machine is the default

.PARAMETER Protocol
Specify protocol to use for test, HTTP, HTTPS or both.
By default only HTTPS is tested.

.EXAMPLE
PS> Test-WinRM HTTP

.EXAMPLE
PS> Test-WinRM -Domain Server1 -Protocol Any

.INPUTS
None. You cannot pipe objects to Test-WinRM

.OUTPUTS
None. Test-WinRM does not generate any output

.NOTES
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Remote registry test
TODO: Default test should be to localhost which must not ask for credentials

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md
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
		[ValidateSet("HTTP", "HTTPS", "Any")]
		[string] $Protocol = "HTTPS"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true
	$PSSessionOption = New-PSSessionOption -UICulture en-US -Culture en-US `
		-OpenTimeout 3000 -CancelTimeout 5000 -OperationTimeout 10000 -MaxConnectionRetryCount 2

	if ($PSSessionConfigurationName -ne "RemoteFirewall")
	{
		Write-Warning -Message "Unexpected session configuration $PSSessionConfigurationName"
	}

	################################################

	$WSManParams = @{
		Authentication = "Default"
		ApplicationName = $PSSessionApplicationName # "wsman"
	}

	if ($Protocol -ne "HTTP")
	{
		if (($Domain -ne ([System.Environment]::MachineName) -or ($Domain -ne "localhost")))
		{
			# NOTE: If using SSL on localhost, it would go trough network stack for which we need authentication
			# Otherwise the error is: "The server certificate on the destination computer (localhost) has the
			# following errors: Encountered an internal error in the SSL library.
			$RemoteCredential = Get-Credential -Message "Credentials are required to access host '$Domain'"
			$WSManParams["ComputerName"] = $Domain
			$WSManParams["Credential"] = $RemoteCredential
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTPS on '$Domain'"
		$WSManParams["Port"] = 5986

		# TODO: -CertificateThumbprint $Cert.Thumbprint -ApplicationName -Port
		Test-WSMan -UseSSL @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}

	if ($Protocol -ne "HTTPS")
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing WinRM service over HTTP on '$Domain'"
		$WSManParams["Port"] = 5985

		Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
	}

	##################################################

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new CIM session to $Domain"
	$CimOptions = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture en-US -Culture en-US

	$CimParams = @{
		Name = "RemoteCim"
		Authentication = "Default"
		OperationTimeoutSec = $PSSessionOption.OperationTimeout.TotalSeconds
	}

	if (Get-Variable -Name RemoteCredential -EA Ignore)
	{
		$CimParams["ComputerName"] = $Domain
		$CimParams["Credential"] = $RemoteCredential
	}

	$CimOptions.UseSsl = $Protocol -ne "HTTP"
	$CimParams["SessionOption"] = $CimOptions

	if (Get-CimSession -Name RemoteCim -ErrorAction Ignore)
	{
		Remove-CimSession -Name RemoteCim
	}

	# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
	# verification is accomplished using a standard WS-Identity operation.
	# NOTE: Specifying computer name may fail if WinRM listens on loopback only
	$CimServer = New-CimSession @CimParams

	# MSDN: Get-CimInstance, if the InputObject parameter is not specified then:
	# Works on local Windows Management Instrumentation (WMI) using a Component Object Model (COM) session
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server on localhost"
	Get-CimInstance -Class Win32_OperatingSystem |
	Select-Object CSName, Caption | Format-Table

	# Works against the CIM server specified by either the ComputerName or the CimSession parameter
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Testing CIM server on '$Domain'"
	Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
	Select-Object CSName, Caption | Format-Table
}
