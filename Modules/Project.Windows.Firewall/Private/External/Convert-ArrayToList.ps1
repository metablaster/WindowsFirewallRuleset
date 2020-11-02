
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes

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
Convert String array to comma separated list

.DESCRIPTION
Convert String array to comma separated list

.PARAMETER StringArray
String array which to convert

.EXAMPLE
TODO: provide example and description

.INPUTS
None. You cannot pipe objects to Convert-ArrayToList

.OUTPUTS
[string] comma separated list

.NOTES
None.
#>
function Convert-ArrayToList
{
	[OutputType([string])]
	param(
		[Parameter()]
		[string[]] $StringArray
	)

	if ($StringArray)
	{
		[string] $Result = ""
		foreach ($Value In $StringArray)
		{
			if ($Result -ne "")
			{
				$Result += ","
			}

			$Result += $Value
		}
		return $Result
	}
	else
	{
		return ""
	}
}
