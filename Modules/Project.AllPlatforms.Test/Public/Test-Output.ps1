
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
Verify TypeName and OutputType are identical

.DESCRIPTION
The purpose of this test is is to ensure object output typename is identical as
described by OutputType attribute.
Comparison is case sensitive.

.PARAMETER OutputObject
The actual .NET object that some function returns

.PARAMETER Command
CommandInfo object obtained from Get-Command

.EXAMPLE
PS> $Result = Some-Function
PS> Test-Output $Result -Command Some-Function

.INPUTS
None. You cannot pipe objects to Test-Output

.OUTPUTS
[System.String] TypeName and OutputType including equality test

.NOTES
None.
#>
function Test-Output
{
	[OutputType([string])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[System.Object] $OutputObject,

		[Parameter(Mandatory = $true)]
		[string] $Command
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	Start-Test "Compare TypeName and OutputType"

	$TypeName = Get-TypeName $OutputObject
	$OutputType = Get-TypeName -Command $Command

	"TypeName:`t$TypeName"
	"OutputType:`t$OutputType"

	if ($OutputType -ceq $TypeName)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] TypeName and OutputType are identical"
	}
	else
	{
		Write-Error -Category InvalidResult -TargetObject $TypeName `
			-Message "TypeName and OutputType are not identical"
	}

	Stop-Test
}
