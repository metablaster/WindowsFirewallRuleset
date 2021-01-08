
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
Converts either an unsigned 32-bit integer or a dotted binary string to an IP Address.

.DESCRIPTION
ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.

.PARAMETER IPAddress
A string representation of an IP address from either UInt32 or dotted binary.

.EXAMPLE
PS> ConvertTo-DottedDecimalIP 11000000.10101000.00000000.00000001

Convert the binary form back to dotted decimal, resulting in 192.168.0.1.

.EXAMPLE
PS> ConvertTo-DottedDecimalIP 3232235521

Convert the decimal form back to dotted decimal, resulting in 192.168.0.1.

.INPUTS
[string] IP address

.OUTPUTS
[IPAddress] IP address

.NOTES
Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DottedDecimalIP.md

.LINK
https://github.com/indented-automation/Indented.Net.IP
#>
function ConvertTo-DottedDecimalIP
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DottedDecimalIP.md")]
	[OutputType([IPAddress])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string] $IPAddress
	)

	process
	{
		try
		{
			[int64] $Value = 0

			if ([int64]::TryParse($IPAddress, [ref] $Value))
			{
				return [IPAddress]([IPAddress]::NetworkToHostOrder([int64] $Value) -shr 32 -band [uint32]::MaxValue)
			}
			else
			{
				[IPAddress][uint64][convert]::ToUInt32($IPAddress.Replace('.', ''), 2)
			}
		}
		catch
		{
			$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
				[ArgumentException] "Cannot convert this format.",
				"UnrecognizedFormat",
				"InvalidArgument",
				$IPAddress
			)
			Write-Error -ErrorRecord $ErrorRecord
		}
	}
}
