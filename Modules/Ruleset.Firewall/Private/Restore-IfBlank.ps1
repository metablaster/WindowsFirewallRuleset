
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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

.DESCRIPTION

.PARAMETER Value
Input value which is returned without modification

.PARAMETER DefaultValue
Value to set if a input is empty.
This way calling code can be generic since it doesn't need to handle default values

.EXAMPLE
PS> Restore-IfBlank

.EXAMPLE
PS> Restore-IfBlank "NewValue"

.INPUTS
None. You cannot pipe objects to Restore-IfBlank

.OUTPUTS
[string]

.NOTES
None.
#>
function Restore-IfBlank
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([string])]
	param (
		[Parameter(Position = 0)]
		[string] $Value,

		[Parameter()]
		$DefaultValue = "Any"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (![string]::IsNullOrEmpty($Value))
	{
		return $Value
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Input is missing, using default value of: '$DefaultValue'"
		return $DefaultValue
	}
}
