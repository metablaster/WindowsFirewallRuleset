
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Convert encoded single line string to multi line string array

.DESCRIPTION
Convert encoded single line string to multi line CRLF string array
Input string `r is encoded as %% and `n as ||
This function is used to dencode encoded firewall rule multiline description

.PARAMETER Value
String which to convert

.PARAMETER JSON
Input string is from JSON file, meaning no need to decode

.EXAMPLE
PS> Convert-ListToMultiLine "Some%%||String"

Some
String

.INPUTS
None. You cannot pipe objects to Convert-ListToMultiLine

.OUTPUTS
[string] multi line string

.NOTES
None.
#>
function Convert-ListToMultiLine
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([string])]
	param (
		[Parameter(Position = 0)]
		[Alias("List")]
		[string] $Value,

		[Parameter()]
		[switch] $JSON
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ([string]::IsNullOrEmpty($Value))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Input is missing, result is empty string"
		return ""
	}

	# replace encoded string with new line
	if ($JSON)
	{
		return $Value
	}
	else
	{
		# For CSV files need to encode multi line rule description into single line
		return $Value.Replace("%%", "`r").Replace("||", "`n")
	}
}
