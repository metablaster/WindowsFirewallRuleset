
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
Convert multi line string array to single line string
.DESCRIPTION
Convert multi line string array to single line string
`r is encoded as %% and `n as ||
.PARAMETER MultiLine
String array which to convert
.PARAMETER JSON
Input string will go to JSON file, meaning no need to encode
.EXAMPLE
Convert-MultiLineToList "Some`rnString"
Produces: Some||String
.INPUTS
None. You cannot pipe objects to Convert-ArrayToList
.OUTPUTS
[string] comma separated list
.NOTES
None.
#>
function Convert-MultiLineToList
{
	[OutputType([string])]
	param(
		[Parameter()]
		[string] $MultiLine,

		[Parameter()]
		[switch] $JSON
	)

	if ([string]::IsNullOrEmpty($MultiLine))
	{
		return ""
	}

	# replace new line with encoded string
	# For CSV files need to encode multi line rule description into single line
	if ($JSON)
	{
		return $MultiLine
	}
	else
	{
		return $MultiLine.Replace("`r", "%%").Replace("`n", "||")
	}
}
