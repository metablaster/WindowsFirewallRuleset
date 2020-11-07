
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
Convert comma separated list to string array

.DESCRIPTION
Convert comma separated list to string array
Used by Import-FirewallRules ex. to unpack a list of IP addresses back to string array

.PARAMETER List
List of comma separated string values, previously packed with Convert-ArrayToList

.PARAMETER DefaultValue
Value to return if a list is empty

.EXAMPLE
PS> Convert-ArrayToList "192.168.1.1,192.168.2.1,172.24.33.100"

"192.168.1.1", "192.168.2.1", "172.24.33.100"

.INPUTS
None. You cannot pipe objects to Convert-ListToArray

.OUTPUTS
[string]

.NOTES
TODO: DefaultValue can't be string, try string[]
#>
function Convert-ListToArray
{
	[CmdletBinding()]
	[OutputType([string])]
	param(
		[Parameter()]
		[string] $List,

		[Parameter()]
		$DefaultValue = "Any"
	)

	if (![string]::IsNullOrEmpty($List))
	{
		return ($List -split ",")
	}
	else
	{
		return $DefaultValue
	}
}
