
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
Start test case

.DESCRIPTION
Start-Test writes output to host to separate test cases.
Formatted message block is shown in the console.
This function must be called before single test case starts executing

.PARAMETER Message
Message to format and print before test case begins.
This message is appended to command being tested and then printed.

.PARAMETER Expected
Expected output of a test.
This value is appended to Message.

.PARAMETER Command
The command which is to be tested.
This value overrides default Command parameter specified in Enter-Test.

.EXAMPLE
PS> Start-Test "some test"

************************************
* Testing: Get-Something some test *
************************************

.EXAMPLE
PS> Start-Test "some test" -Expected "output 123" -Command "Set-Something"

*****************************************************
* Testing: Set-Something some test -> output 123 *
*****************************************************

.INPUTS
None. You cannot pipe objects to Start-Test

.OUTPUTS
[string]

.NOTES
TODO: switch for no new line, some tests will produce redundant new lines, ex. Format-Table in pipeline
TODO: Doesn't work starting tests inside dynamic modules
TODO: Write-Information instead of Write-Output
#>
function Start-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Start-Test.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[AllowEmptyString()]
		[string] $Message,

		[Parameter()]
		[string] $Expected,

		[Parameter()]
		[string] $Command
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# TODO: This regex won't cover everything
	# "Start-Test -Param input"
	# Let Stop-Test know test case name
	Set-Variable -Name TestCase -Scope Script -Value ([regex]::Match($Message, "^\w+-\w+(?=\s)"))

	if ($PSCmdlet.ShouldProcess("Start test case", $Message))
	{
		if (![string]::IsNullOrEmpty($Command))
		{
			$OutputString = "Testing: $Command $Message"
		}
		elseif (Get-Variable -Name TestCommand -Scope Script -ErrorAction Ignore)
		{
			$OutputString = "Testing: $script:TestCommand $Message"
		}
		else
		{
			$OutputString = "Testing: $Message"
		}

		if (![string]::IsNullOrEmpty($Expected))
		{
			$OutputString += " -> $Expected"
		}

		$Asterisks = ("*" * ($OutputString.Length + 4))

		# NOTE: Write-Host would mess up test case outputs
		Write-Output ""
		Write-Output $Asterisks
		Write-Output "* $OutputString *"
		Write-Output $Asterisks
		Write-Output ""
	}
}
