
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
Stop test case

.DESCRIPTION
Restore-Test writes output to console after test case is done
This function must be called after single test case is done executing

.EXAMPLE
PS> Restore-Test

.INPUTS
None. You cannot pipe objects to Restore-Test

.OUTPUTS
None. Restore-Test does not generate any output

.NOTES
None.
#>
function Restore-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Restore-Test.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (!(Get-Variable -Name TestCase -Scope Script -ErrorAction Ignore))
	{
		Write-Error -Category InvalidOperation -TargetObject $MyInvocation.InvocationName `
			-Message "You forgot to call Start-Test -Force prior to calling Restore-Test"
		return
	}

	if ($PSCmdlet.ShouldProcess($script:TestCase, "Restore test case failure reporting"))
	{
		if (Get-Variable -Name PreviousErrorPreference -Scope Script -ErrorAction Ignore)
		{
			# Restore previous ErrorActionPreference
			# NOTE: Does not work for functions withing module, see hack and workaround in Start-Test
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Global ErrorAction is '$global:ErrorActionPreference'"
			$global:ErrorActionPreference = $script:PreviousErrorPreference

			# Convert stored generated error message to informational message
			$private:TestEV = (Get-Variable -Name TestEV -Scope Global).Value
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Global TestEV is '$private:TestEV'"

			foreach ($ErrorRecord in $private:TestEV)
			{
				# TODO: Info output is not printed after Start-Test header
				# TODO: Consider colored message with Write-ColorMessage
				Write-Information -Tags "Test" -MessageData "INFO: $ErrorRecord"
			}

			# Remove variables because Start-Test will renew them
			Remove-Variable -Name TestEV -Scope Global
			Remove-Variable -Name PreviousErrorPreference -Scope Script
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Test case '$script:TestCase' done"
		}
		else
		{
			Write-Error -Category InvalidOperation -TargetObject $script:TestCase `
				-Message "You forgot to use -Force with Start-Test prior to calling Restore-Test"
		}
	}
}
