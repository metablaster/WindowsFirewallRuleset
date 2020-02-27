
<#
Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses bellow
#>

<#
MIT License

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
Convert a mask length to a dotted-decimal subnet mask.
.DESCRIPTION
ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging between 0 and 32.

ConvertTo-Mask creates a binary string from the length,
converts the string to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.
.INPUTS
System.Int32
.EXAMPLE
ConvertTo-Mask 24

Returns the dotted-decimal form of the mask, 255.255.255.0.
.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consisten with project: code formatting and symbol casing.
#>
function ConvertTo-Mask {
    [CmdletBinding()]
    [OutputType([IPAddress])]
    param (
        # The number of bits which must be masked.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [Alias('Length')]
        [ValidateRange(0, 32)]
        [byte] $MaskLength
    )

    process {
        [IPAddress][UInt64][Convert]::ToUInt32(('1' * $MaskLength).PadRight(32, '0'), 2)
    }
}
