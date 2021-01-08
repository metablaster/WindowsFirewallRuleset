
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
Un-initialize and exit unit test

.DESCRIPTION
Exit-Test performs finishing steps after unit test is done, ie. to restore previous state
Must be called in pair with Enter-Test and after all test cases are done in single unit test

.PARAMETER Pester
Should be specified to exit private function pester test

.EXAMPLE
PS> Exit-Test

.EXAMPLE
PS> Exit-Test -Pester

.INPUTS
None. You cannot pipe objects to Exit-Test

.OUTPUTS
None. Exit-Test does not generate any output

.NOTES
None.
#>
function Exit-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Exit-Test.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Pester
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if (!$Pester -and $PSCmdlet.ShouldProcess("Exit unit test", $UnitTest))
	{
		# Remove resources created by Enter-Test
		Remove-Module -Name Dynamic.UnitTest -Force

		Write-Output ""
		Write-Information -Tags "Test" -MessageData "INFO: Exiting unit test '$UnitTest'"
		Remove-Variable -Name UnitTest -Scope Global -Force
	}
}
