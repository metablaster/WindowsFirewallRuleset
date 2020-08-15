
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses below
#>

<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

Copyright (C) 2016, Chris Dent

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
Converts a hexadecimal IP address into a dotted decimal string.
.DESCRIPTION
ConvertFrom-HexIP takes a hexadecimal string and returns a dotted decimal IP address.
An intermediate call is made to ConvertTo-DottedDecimalIP.
.PARAMETER IPAddress
An IP Address to convert.
.EXAMPLE
ConvertFrom-HexIP c0a80001

Returns the IP address 192.168.0.1.
.INPUTS
System.String
.OUTPUTS
TODO: describe outputs
.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project: code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function ConvertFrom-HexIP
{
	[CmdletBinding()]
	[OutputType([IPAddress])]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[ValidatePattern('^(0x)?[0-9a-f]{8}$')]
		[string] $IPAddress
	)

	process
	{
		[IPAddress][UInt64][convert]::ToUInt32($IPAddress, 16)
	}
}
