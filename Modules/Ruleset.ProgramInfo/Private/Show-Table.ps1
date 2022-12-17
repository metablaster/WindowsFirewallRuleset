
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
Print installation directories to console

.DESCRIPTION
Prints found program data which includes program name, program ID, install location etc.

.PARAMETER Caption
Single line string to print before printing the table

.EXAMPLE
PS> Show-Table "Table data"

.INPUTS
None. You cannot pipe objects to Show-Table

.OUTPUTS
None. Show-Table does not generate any output

.NOTES
TODO: Needs to be tested if Write-Host can be removed
TODO: PSScriptAnalyzer doesn't report use of Write-Host here, why?
#>
function Show-Table
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[string] $Caption
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (!(Get-Variable -Name InstallTable -Scope Script -ErrorAction Ignore))
	{
		Write-Error -Category InvalidOperation -TargetObject $MyInvocation.InvocationName `
			-Message "Initialize-Table was not called prior to Show-Table"
		return
	}

	if (![string]::IsNullOrEmpty($Caption))
	{
		Write-Host $Caption
	}

	$InstallTable | Format-Table -AutoSize | Out-Host
}
