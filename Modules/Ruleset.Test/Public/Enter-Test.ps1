
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
Initialize unit test

.DESCRIPTION
Enter-Test initializes unit test
Must be called before first test case in single unit test and in pair with Exit-Test

.PARAMETER Command
Optionally specify the command which is to be tested by default.
This value is used by Start-Test function by default unless specified in Start-Test.

.PARAMETER Private
If specified, temporarily exports private module functions into global scope

.PARAMETER Pester
Should be specified to enter pester tests for private functions,
this parameter implies -Private switch.

.EXAMPLE
PS> Enter-Test

.EXAMPLE
PS> Enter-Test -Command "Get-Something"

.EXAMPLE
PS> Enter-Test -Private

.INPUTS
None. You cannot pipe objects to Enter-Test

.OUTPUTS
None. Enter-Test does not generate any output

.NOTES
None.
#>
function Enter-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Enter-Test.md")]
	[OutputType([void])]
	param (
		[Parameter(Position = 0)]
		[string] $Command,

		[Parameter()]
		[switch] $Private,

		[Parameter()]
		[switch] $Pester
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Let Exit-Test know file name
	if ($Pester)
	{
		$Private = $true
		$UnitTest = (Get-PSCallStack)[1].Command -replace "\.\w{2,3}1$"
	}
	else
	{
		# NOTE: Global scope because this module could be removed before calling Exit-Test
		# NOTE: This will fail if Exit-Test was not called, run Exit-Test manually in that case
		if (Get-Variable -Name UnitTest -Scope Global -ErrorAction Ignore)
		{
			Write-Warning -Message "Either previous unit test did not complete or test module was reloaded"
		}
		else
		{
			New-Variable -Name UnitTest -Scope Global -Option ReadOnly -Value ((Get-PSCallStack)[1].Command -replace "\.\w{2,3}1$")
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Entering unit test '$UnitTest'"

		if (![string]::IsNullOrEmpty($Command))
		{
			Set-Variable -Name TestCommand -Scope Script -Option ReadOnly -Force -Value $Command
		}
	}

	if ($PSCmdlet.ShouldProcess("Enter unit test", $UnitTest))
	{
		New-Module -Name Dynamic.UnitTest -ArgumentList $Private -ScriptBlock {
			param ($Private)

			if ($Private)
			{
				# Temporarily export private functions to global scope
				$PrivateScript = Get-ChildItem -Path "$ProjectRoot\Modules\*\Private" -Filter *.ps1 -Recurse
				$PrivateScript += Get-ChildItem -Path "$ProjectRoot\Modules\*\Private\External" -Filter *.ps1 -Recurse

				foreach ($Script in $PrivateScript) { . $Script.FullName }
				Export-ModuleMember -Function *
			}
		} | Import-Module -Scope Global
	}
}
