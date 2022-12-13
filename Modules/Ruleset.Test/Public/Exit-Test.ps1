
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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

.PARAMETER Private
Should be specified to exit test that was entered with Enter-Test -Private

.EXAMPLE
PS> Exit-Test

.EXAMPLE
PS> Exit-Test -Private

.INPUTS
None. You cannot pipe objects to Exit-Test

.OUTPUTS
[string]

.NOTES
TODO: Write-Information instead of Write-Output, but problem is that is may be logged
#>
function Exit-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Exit-Test.md")]
	[OutputType([string])]
	param (
		[Parameter()]
		[switch] $Private
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (!(Get-Variable -Name UnitTest -Scope Global -ErrorAction Ignore))
	{
		Write-Error -Category InvalidOperation -TargetObject $MyInvocation.InvocationName `
			-Message "Exit-Test cannot be called without Enter-Test"
		return
	}
	elseif (Get-Variable -Name PreviousErrorPreference -Scope Script -ErrorAction Ignore)
	{
		# Hard error, any further testing is pointless since errors would be silent
		Write-Error -Category InvalidOperation -TargetObject $MyInvocation.InvocationName `
			-Message "You forgot to call Restore-Test in '$UnitTest' unit test" -ErrorAction Stop
	}

	if ($PSCmdlet.ShouldProcess($UnitTest, "Exit unit test"))
	{
		$DynamicModule = Get-Module -Name Dynamic.UnitTest -ErrorAction Ignore

		if ($Private)
		{
			# Remove resources created by Enter-Test
			Remove-Module -ModuleInfo $DynamicModule
		}
		elseif ($DynamicModule)
		{
			Write-Error -Category InvalidOperation -TargetObject $DynamicModule `
				-Message "You forgot to specify -Private switch for Exit-Test somewhere"
		}

		# NOTE: Write-Host would mess up test case outputs
		Write-Output ""
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exiting unit test '$UnitTest'"
		Remove-Variable -Name UnitTest -Scope Global -Force

		# Command name which was tested and specified with Enter-Test -Command
		if (Get-Variable -Name TestCommand -Scope Script -ErrorAction Ignore)
		{
			Remove-Variable -Name TestCommand -Scope Script -Force
		}
	}
}
