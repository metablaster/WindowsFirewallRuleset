
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
Test target computer (policy store) to which to deploy firewall

.DESCRIPTION
The purpose of this function is to reduce checks, depending on whether PowerShell
Core or Desktop edition is used, since parameters for Test-Connection are not the same
for both PowerShell editions.

.PARAMETER Domain
Target computer which to test

.PARAMETER Retry
Valid only for PowerShell Core. Specifies the number of echo requests to send. The default value is 4

.PARAMETER Timeout
Valid only for PowerShell Core. The test fails if a response isn't received before the timeout expires

.EXAMPLE
PS> Test-TargetComputer "COMPUTERNAME"

.EXAMPLE
PS> Test-TargetComputer "COMPUTERNAME" -Count 2 -Timeout 1

.INPUTS
None. You cannot pipe objects to Test-TargetComputer

.OUTPUTS
[bool] false or true if target host is responsive

.NOTES
TODO: partially avoiding error messages, check all references which handle errors (code bloat)
TODO: We should check for common issues for GPO management, not just ping status (ex. Test-NetConnection)
TODO: Credential request for remote policy store should be initialized here
#>
function Test-TargetComputer
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Desktop",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-TargetComputer.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[ValidateRange(1, [int16]::MaxValue)]
		[int16] $Retry = $RetryCount,

		[Parameter()]
		[ValidateScript( { $PSVersionTable.PSEdition -eq "Core" } )]
		[ValidateRange(1, [int16]::MaxValue)]
		[int16] $Timeout = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Be quiet for localhost
	if ($Domain -ne [System.Environment]::MachineName)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Contacting computer $Domain"
	}

	# Test parameters depend on PowerShell edition
	# TODO: changes not reflected in calling code
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		# TODO: It will be set to 0
		if (!$Timeout)
		{
			# TODO: Can't modify Timeout parameter
			$Timeout = $ConnectionTimeout
		}

		if ($ConnectionIPv4)
		{
			$Status = Test-Connection -TargetName $Domain -Count $Retry -TimeoutSeconds $Timeout -Quiet -IPv4 -EA Stop
		}
		else
		{
			$Status = Test-Connection -TargetName $Domain -Count $Retry -TimeoutSeconds $Timeout -Quiet -IPv6 -EA Stop
		}
	}
	else
	{
		$Status = Test-Connection -ComputerName $Domain -Count $Retry -Quiet -EA Stop
	}

	if (!$Status -and ($Domain -ne [System.Environment]::MachineName))
	{
		Write-Error -Category ResourceUnavailable -TargetObject $Domain -Message "Unable to contact computer: $Domain"
	}

	return $Status
}
