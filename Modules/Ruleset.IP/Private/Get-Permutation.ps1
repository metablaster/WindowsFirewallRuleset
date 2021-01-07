
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
ISC License

Copyright (C) 2016 Chris Dent

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#>

<#
.SYNOPSIS
Gets permutations of an IP address expansion expression.

.DESCRIPTION
Gets permutations of an IP address expansion expression.

.PARAMETER Group
ExpansionGroupInfo custom object, the result of IP wildcard pattern expansion

.PARAMETER BaseAddress
Initial IP address conaining Wildcard pattern

.PARAMETER Index
Index of the Group parameter array which to process

.EXAMPLE
See Resolve-IPAddress.ps1

.INPUTS
None. You cannot pipe objects to Get-Permutation

.OUTPUTS
[string]

.NOTES
Modifications by metablaster year 2019, 2020:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Rename function to approved verb
- Removed unnecessary position arguments, added default argument values explicitly.
Modifications 2021:
- Added OutputType attribute
- Update comment based help
#>
function Get-Permutation
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[PSTypeName("ExpansionGroupInfo")]
		[object[]] $Group,

		[Parameter(Mandatory = $true)]
		[string] $BaseAddress,

		[Parameter()]
		[int32] $Index = 0
	)

	foreach ($Value in $Group[$Index].ReplaceWith)
	{
		$Octets = $BaseAddress -split '\.'
		$Octets[$Group[$Index].Position] = $Value
		$Address = $Octets -join '.'

		if ($Index -lt $Group.Count - 1)
		{
			$Address = Get-Permutation $Group -Index ($Index + 1) -BaseAddress $Address
		}

		Write-Output $Address
	}
}
