
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Exit unit test

.DESCRIPTION
Exit-Test performs finishing steps after unit test is done, ie. to restore previous state
This function must be called after all test cases are done in single unit test

.EXAMPLE
PS> Exit-Test

.INPUTS
None. You cannot pipe objects to Exit-Test

.OUTPUTS
None. Exit-Test does not generate any output

.NOTES
None.
#>
function Exit-Test
{
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Test/Help/en-US/Exit-Test.md")]
	param()

	if ($PSCmdlet.ShouldProcess("Exit unit test", $script:UnitTest))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# restore logging errors
		Set-Variable -Name ErrorLogging -Scope Global -Value $ErrorLoggingCopy

		# restore logging warnings
		Set-Variable -Name WarningLogging -Scope Global -Value $WarningLoggingCopy

		# restore logging information messages
		Set-Variable -Name InformationLogging -Scope Global -Value $InformationLoggingCopy

		Write-Debug -Message "[$($MyInvocation.InvocationName)] ErrorLogging restored to: $ErrorLogging"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] WarningLogging restored to: $WarningLogging"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] InformationLogging restored to: $InformationLogging"

		Write-Output ""
		Write-Information -Tags "Test" -MessageData "INFO: Exiting unit test '$script:UnitTest'"
	}
}
