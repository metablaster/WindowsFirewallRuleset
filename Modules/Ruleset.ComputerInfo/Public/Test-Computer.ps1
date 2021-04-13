
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Test target computer (policy store) on which to deploy firewall

.DESCRIPTION
The purpose of this function is network test consistency, depending on whether PowerShell
Core or Desktop edition is used and depending on kind of test needed, since parameters are
different for Test-Connection, Test-NetConnection, Test-WSMan, PS edition etc.

.PARAMETER Domain
Target computer which to test for connectivity

.PARAMETER Protocol
Specify the kind of a test to perform.
Acceptable values are WSMan and Ping
The default is WSMan.

.PARAMETER Credential
Specify credentials required for authentication

.PARAMETER Authentication
Specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.

.PARAMETER Retry
Specifies the number of echo requests to send.
The default value is 4.
Valid only for PowerShell Core
The default value is defined in $PSSessionOption preference variable

.PARAMETER Timeout
The test fails if a response isn't received before the timeout expires.
Valid only for PowerShell Core.
The default value is 2 seconds.

.EXAMPLE
PS> Test-Computer "Server1" -Credential (Get-Credential)

.EXAMPLE
PS> Test-Computer "Server2" -Count 2 -Timeout 1 -Protocol Ping

.EXAMPLE
PS> Test-Computer "Server3" -Count 2 -Timeout 1

.INPUTS
None. You cannot pipe objects to Test-Computer

.OUTPUTS
[bool] True if target host is responsive, false otherwise

.NOTES
NOTE: This function currently does nothing useful except testing if CIM session is still alive.
TODO: Partially avoiding error messages, check all references which handle errors (code bloat)
TODO: We should check for common issues for GPO management, not just ping status (ex. Test-NetConnection)
TODO: Test CIM and DCOM
#>
function Test-Computer
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "WSMan",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-Computer.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[ValidateSet("WSMan", "Ping")]
		[string] $Protocol = "WSMan",

		[Parameter(ParameterSetName = "WSMan")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "WSMan")]
		[ValidateSet("None", "Basic", "CredSSP", "Default", "Digest", "Kerberos", "Negotiate", "Certificate")]
		[string] $Authentication = "Default",

		[Parameter(ParameterSetName = "Ping")]
		[ValidateRange(1, [int16]::MaxValue)]
		[int16] $Retry = $PSSessionOption.MaxConnectionRetryCount,

		[Parameter(ParameterSetName = "Ping")]
		[ValidateScript( { $PSVersionTable.PSEdition -eq "Core" } )]
		[ValidateRange(1, [int16]::MaxValue)]
		[int16] $Timeout = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (Get-CimSession -Name RemoteCim)
	{
		$Status = $CimServer.TestConnection()
	}
	else
	{
		$Status = $false
	}

	if (!$Status)
	{
		Write-Error -Category ResourceUnavailable -TargetObject $Domain -Message "Unable to contact computer: $Domain"
	}

	return $Status

	#######################################################################

	if ($Protocol -eq "WSMan")
	{
		$Params = @{
			UseSSL = $CimOptions.UseSsl
			ComputerName = $Domain
			ErrorAction = "SilentlyContinue"
		}

		if ($Authentication -ne "None")
		{
			# NOTE: Otherwise request is sent to the remote computer anonymously,
			# without using authentication, it returns no information that is specific to
			# the operating-system version
			$Params["Authentication"] = $Authentication
		}

		if ($Credential)
		{
			$Params["Credential"] = $Credential
		}
		elseif ($Domain -ne [System.Environment]::MachineName)
		{
			$Params["Credential"] = $RemoteCredential
		}

		# [System.Xml.XmlElement]
		$Status = Test-WSMan @Params
	}
	else
	{
		# Be quiet for localhost
		if ($Domain -ne [System.Environment]::MachineName)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Contacting computer $Domain"
		}

		# Test parameters depend on PowerShell edition
		# TODO: Changes not reflected in calling code
		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# TODO: It will be set to 0
			if (!$Timeout)
			{
				# TODO: Can't modify Timeout parameter
				# TODO: Use $PSSessionOption to control this
				# NOTE: The default value for Test-Connection is 5 seconds
				$Timeout = 2
			}

			if ($ConnectionIPv4)
			{
				# [ManagementObject]
				$Status = Test-Connection -TargetName $Domain -Count $Retry -TimeoutSeconds $Timeout -Quiet -IPv4 -EA Stop
			}
			else
			{
				$Status = Test-Connection -TargetName $Domain -Count $Retry -TimeoutSeconds $Timeout -Quiet -IPv6 -EA Stop
			}
		}
		else
		{
			# NOTE: Test-Connection defaults to IPv6 in Windows PowerShell,
			# if you test NetBios name it will fail because NetBios works only over IPv4
			# $Status = Test-Connection -ComputerName $Domain -Count $Retry -Quiet -EA Stop

			# [NetConnectionResults]
			$Status = Test-NetConnection -ComputerName $Domain |
			Select-Object -ExpandProperty PingSucceeded
		}
	}

	if (!$Status) # -and ($Domain -ne [System.Environment]::MachineName))
	{
		Write-Error -Category ResourceUnavailable -TargetObject $Domain -Message "Unable to contact computer: $Domain"
	}

	Set-Variable -Name LastConnectionTest -Scope Script -Value ($null -ne $Status)
	return $LastConnectionTest
}
