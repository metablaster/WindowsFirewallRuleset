
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
Start test case
.DESCRIPTION
Start-Test writes output to host to separate test cases
This function must be called before single test case starts executing
.PARAMETER Message
Message to format and print before test case begins
.EXAMPLE
PS> Start-Test "Get-Something"

**************************
* Testing: Get-Something *
**************************
.INPUTS
None. You cannot pipe objects to Start-Test
.OUTPUTS
None. Formatted message block is shown in the console
.NOTES
TODO: switch for no new line, some tests will produce redundant new lines, ex. Format-Table in pipeline
#>
function Start-Test
{
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Test/Help/en-US/Start-Test.md")]
	param (
		[AllowEmptyString()]
		[Parameter(Mandatory = $true)]
		[string] $Message
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# "Start-Test -Param input"
	# Let Stop-Test know test case name
	Set-Variable -Name TestCase -Scope Script -Value ([regex]::new("^\w+-\w+(?=\s)").Match($Message))

	if ($PSCmdlet.ShouldProcess("Start test case", $Message))
	{
		$OutputString = "Testing: $Message"
		$Asterisks = ("*" * ($OutputString.Length + 4))

		# NOTE: Write-Host would mess up test case outputs
		Write-Output ""
		Write-Output $Asterisks
		Write-Output "* $OutputString *"
		Write-Output $Asterisks
		Write-Output ""
	}
}
