
<#
Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses below
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
Tests an IP address to determine if it falls within IP address range.
.DESCRIPTION
Test-SubnetMember attempts to determine whether or not an address or range falls within another range.
The network and broadcast address are calculated the converted to decimal then
compared to the decimal form of the submitted address.
.PARAMETER SubjectIPAddress
A representation of the subject, the network to be tested. Either a literal IP address,
a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
.PARAMETER ObjectIPAddress
A representation of the object, the network to test against. Either a literal IP address,
a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
.PARAMETER SubjectSubnetMask
A subnet mask as an IP address.
.PARAMETER ObjectSubnetMask
A subnet mask as an IP address.
.EXAMPLE
Test-SubnetMember -SubjectIPAddress 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/16

Returns true as the subject network can be contained within the object network.
.EXAMPLE
Test-SubnetMember -SubjectIPAddress 192.168.0.0/16 -ObjectIPAddress 192.168.0.0/24

Returns false as the subject network is larger the object network.
.EXAMPLE
Test-SubnetMember -SubjectIPAddress 10.2.3.4/32 -ObjectIPAddress 10.0.0.0/8

Returns true as the subject IP address is within the object network.
.EXAMPLE
Test-SubnetMember -SubjectIPAddress 255.255.255.255 -ObjectIPAddress 0/0

Returns true as the subject IP address is the last in the object network range.
.INPUTS
None. You cannot pipe objects to Test-SubnetMember
.OUTPUTS
TODO: describe outputs
.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project: code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function Test-SubnetMember
{
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $SubjectIPAddress,

		[Parameter(Mandatory = $true, Position = 1)]
		[string] $ObjectIPAddress,

		[Parameter()]
		[string] $SubjectSubnetMask,

		[Parameter()]
		[string] $ObjectSubnetMask
	)

	try
	{
		$subjectNetwork = ConvertTo-Network $SubjectIPAddress $SubjectSubnetMask
		$objectNetwork = ConvertTo-Network $ObjectIPAddress $ObjectSubnetMask
	}
	catch
	{
		throw $_
	}

	# A simple check, if the mask is shorter (larger network) then it won't be a subnet of the object anyway.
	if ($subjectNetwork.MaskLength -lt $objectNetwork.MaskLength)
	{
		return $false
	}

	$subjectDecimalIP = ConvertTo-DecimalIP $subjectNetwork.IPAddress
	$objectDecimalNetwork = ConvertTo-DecimalIP (Get-NetworkAddress $objectNetwork)
	$objectDecimalBroadcast = ConvertTo-DecimalIP (Get-BroadcastAddress $objectNetwork)

	# If the mask is longer (smaller network), then the decimal form of the address must be between the
	# network and broadcast address of the object (the network we test against).
	if ($subjectDecimalIP -ge $objectDecimalNetwork -and $subjectDecimalIP -le $objectDecimalBroadcast)
	{
		return $true
	}
	else
	{
		return $false
	}
}
