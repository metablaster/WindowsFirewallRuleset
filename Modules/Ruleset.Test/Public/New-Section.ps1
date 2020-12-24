
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Print new unit test section

.DESCRIPTION
New-Section prints new section to group multiple test cases.
Useful for unit test with a lof of test cases, for readability.

.PARAMETER Section
Section title

.EXAMPLE
PS> New-Section "This is new section"

.INPUTS
None. You cannot pipe objects to New-Section

.OUTPUTS
None. New-Section does not generate any output

.NOTES
TODO: Write-Information instead of Write-Output
#>
function New-Section
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/New-Section.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Message
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("Current unit test", "Print new section"))
	{
		$OutputString = "SECTION -> $Message <- SECTION"
		# The constant is the number of asterisks + spaces on both sides set manually below
		$Asterisks = ("*" * ($OutputString.Length + 22))
		$Dashes = ("-" * ($OutputString.Length + 20))

		# NOTE: Write-Host would mess up test case outputs
		Write-Output ""
		Write-Output ""
		Write-Output $Asterisks

		Write-Output "*$Dashes*"
		Write-Output "*--------- $OutputString ---------*"
		Write-Output "*$Dashes*"

		Write-Output $Asterisks
		Write-Output ""
		Write-Output ""
	}
}
