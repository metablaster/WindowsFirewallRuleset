
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Start-Test writes formatted header block the console for separate test cases.
This function should be called before single test case starts executing.

.PARAMETER Message
Message to format and print before test case begins.
This message is appended to command being tested and then printed.

.PARAMETER Expected
Expected output of a test.
This value is appended to Message.

.PARAMETER Command
The command which is to be tested, it's inserted into message.
This value overrides default Command parameter specified in Enter-Test.

.PARAMETER Force
Used to test, test cases expected to fail.
When specified a global "TestEV" error variable is created and reused by Restore-Test,
errors generated for test case are silenced and converted to informational message.
However this works only for global functions, see example below for a workaround.

.EXAMPLE
PS> Start-Test "some test"

Prints formatted header

.EXAMPLE
PS> Start-Test "some test" -Expected "output 123" -Command "Set-Something"

Prints formatted header

.EXAMPLE
PS> Start-Test "some test" -Force
PS> Function-WhichFails -ErrorVariable TestEV -EA SilentlyContinue
PS> Restore-Test

Error is converted to informational message with Restore-Test.
Here TestEV is a global error variable made with -Force switch, -EA SilentlyContinue must
be specified only for module functions.

.INPUTS
None. You cannot pipe objects to Start-Test

.OUTPUTS
[string]

.NOTES
TODO: Switch for no new line, some tests will produce redundant new lines, ex. Format-Table on pipeline
TODO: Doesn't work for starting tests inside dynamic modules
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
		[string] $Command,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

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

		# To let Restore-Test know test case name, remove "Testing: " portion
		Set-Variable -Name TestCase -Scope Script -Value ($OutputString.Remove(0, 9))

		if (![string]::IsNullOrEmpty($Expected))
		{
			$OutputString += " -> Expected: $Expected"
		}

		# +4 is asterisk and space at each end of a message
		$Asterisks = ("*" * ($OutputString.Length + 4))

		# NOTE: Write-Host would mess up test case outputs
		Write-Output ""
		Write-Output $Asterisks
		Write-Output "* $OutputString *"
		Write-Output $Asterisks
		Write-Output ""

		if ($Force)
		{
			if (Get-Variable -Name PreviousErrorPreference -Scope Script -ErrorAction Ignore)
			{
				# Hard error, any further testing is pointless since errors would be silent
				Write-Error -Category InvalidOperation -TargetObject $script:PreviousErrorPreference `
					-Message "You forgot to call Restore-Test on failure test case" -ErrorAction Stop
			}

			# To let Restore-Test know previous ErrorActionPreference and to convert error to info,
			# also used by Exit-Test to check Restore-Test was called after Start-Test -Force
			New-Variable -Name PreviousErrorPreference -Scope Script -Value $global:ErrorActionPreference

			# HACK: Setting global ErrorActionPreference will not affect ErrorActionPreference in modules
			# A workaround is -EA SilentlyContinue on function that fails.
			# When this is resolved remove -EA SilentlyContinue in unit tests
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Global ErrorAction is '$global:ErrorActionPreference'"
			$global:ErrorActionPreference = "SilentlyContinue"

			# Failure test case which produces errors should use this error variable as -EV +TestEV
			# HACK: Not working in some cases, see Get-UserGroup and Test-Computer unit test shows blank INFO and
			# Test-UPN, Test-Service unit test shows no info at all nor any output
			New-Variable -Name TestEV -Scope Global -Value $null
		}
	}
}
